extends RefCounted

const Types = preload("w4rm_types.gd")
const Tables = preload("w4rm_table.gd")

const VALID_TRIGGER_TYPES = {
	before_insert = "BEFORE INSERT",
	after_insert = "AFTER INSERT",
	before_update = "BEFORE UPDATE",
	after_update = "AFTER UPDATE",
	before_delete = "BEFORE DELETE",
	after_delete = "AFTER DELETE",
}

static func sql_identifier(p_name: String) -> String:
	return '"%s"' % p_name.replace('"', '_')


static func sql_string(p_string: String) -> String:
	return "'%s'" % p_string.replace("'", "\\'")


static func sql_type(p_type) -> String:
	if p_type is Types.W4RMArrayType:
		return sql_identifier(str(p_type.base_type_name)) + " ARRAY"
	elif p_type is Types.W4RMBaseType:
		return str(p_type.name)
	elif p_type is Types.W4RMMapType:
		return sql_identifier(str(p_type.base_type_name)) + " ARRAY"
	return sql_identifier(str(p_type.name))


static func sql_json_cast(p_attr, p_type) -> String:
	if p_type is Types.W4RMArrayType or p_type is Types.W4RMMapType:
		return "(select coalesce(array_agg(item), array[]::%s[]) from jsonb_populate_recordset(null::%s, $1->%s) as item)" % [
			sql_identifier(p_type.base_type_name),
			sql_identifier(p_type.base_type_name),
			sql_string(p_attr)]
	elif p_type.name == &"uuid":
		return "$1->>%s" % [sql_string(p_attr)]
	elif p_type.name == &"timestamp":
		return "($1->>%s)::timestamp" % [sql_string(p_attr)]
	return "$1->%s" % [sql_string(p_attr)]


static func make_transaction(p_queries: Array) -> String:
	return """BEGIN;
	%s
END;""" % ["\n".join(p_queries)]


static func get_create_cast_function(p_type_name: String, p_type_members: Dictionary) -> String:
	return """
	create or replace function jsonb_to_%s(jsonb)
	returns {{TYPE}}
	language sql
	as $BODY$ select ROW(%s)::{{TYPE}} $BODY$;
	DO $$ BEGIN
		create cast (jsonb as {{TYPE}}) with function jsonb_to_%s(jsonb) as assignment;
	EXCEPTION
		WHEN duplicate_object THEN null;
	END $$;
	""".replace("{{TYPE}}", sql_identifier(p_type_name)) % [
		p_type_name,
		", ".join(p_type_members.keys().map(func(k): return sql_json_cast(k, p_type_members[k]))),
		p_type_name
	]


static func get_drop_cast_function(p_type_name: String, p_cascade:=false) -> String:
	return """
		DROP CAST IF EXISTS (jsonb as %s) {{CASCADE}};
		DROP FUNCTION IF EXISTS jsonb_to_%s {{CASCADE}};
	""".replace("{{CASCADE}}", "CASCADE" if p_cascade else "") % [sql_identifier(p_type_name), p_type_name]


static func get_create_type(p_type) -> String:
	var tlines := []
	var slines := []
	var members : Dictionary = p_type.get_members_types()
	for k in members:
		tlines.append("%s %s" % [sql_identifier(k), sql_type(members[k])])
	return """
	DO $$ BEGIN
		create type {{TYPE}} as (
			%s
		);
	EXCEPTION
		WHEN duplicate_object THEN null;
	END $$;
	%s
	""".replace("{{TYPE}}", sql_identifier(p_type.name)) % [
		",\n\t\t\t".join(tlines),
		get_create_cast_function(p_type.name, members)
	]


static func get_drop_type(p_type_name: String, p_cascade:=false) -> String:
	var cascade = "CASCADE" if p_cascade else ""
	return """
		DROP CAST IF EXISTS (jsonb as {{TYPE}}) {{CASCADE}};
		DROP FUNCTION IF EXISTS jsonb_to_%s(jsonb) {{CASCADE}};
		DROP TYPE IF EXISTS {{TYPE}} {{CASCADE}};
		""".replace("{{TYPE}}", sql_identifier(p_type_name)).replace("{{CASCADE}}", cascade) % [p_type_name]


static func get_create_foreign_key(p_source_table: String, p_source_column: String,
		p_schema: String, p_table: String, p_column: String) -> String:
	var fkname = "%s_%s_%s_%s_%s_fkey" % [p_source_table, p_source_column, p_schema, p_table, p_column]
	return """
	DO $$ BEGIN
		ALTER TABLE %s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s.%s (%s) DEFERRABLE INITIALLY IMMEDIATE;
	EXCEPTION
		WHEN duplicate_object THEN null;
	END $$;
	""" % [
		sql_identifier(p_source_table),
		sql_identifier(fkname),
		sql_identifier(p_source_column),
		sql_identifier(p_schema),
		sql_identifier(p_table),
		sql_identifier(p_column),
	]


static func get_column_options(p_table, p_member: StringName) -> Array:
	var opts = []
	if p_member == p_table.get_table_id_name():
		opts.append("PRIMARY KEY")
	var opt = p_table.get_table_options().get(p_member, null)
	if opt == null:
		# Sweet defaults
		opts.append("NOT NULL")
		return opts
	# Nullness
	if opt.nullable:
		opts.append("NULL")
	else:
		opts.append("NOT NULL")
	# Unique values
	if opt.unique:
		opts.append("UNIQUE")
	# Default value (expression)
	if opt.default != &"":
		opts.append("DEFAULT %s" % [opt.default])
	return opts


static func get_create_table(p_table) -> String:
	var columns := []
	var members = p_table.get_table_members_types()
	for k in members:
		columns.append("%s %s %s" % [
			sql_identifier(k),
			sql_type(members[k]),
			" ".join(get_column_options(p_table, k))
		])
	return """
	CREATE TABLE IF NOT EXISTS %s (
		%s
	);""" % [sql_identifier(p_table.get_table_name()), ",\n\t\t".join(columns)] + get_create_cast_function(p_table.get_table_name(), members)


static func get_create_table_foreign_keys(p_table) -> Array:
	var out = []
	var opts = p_table.get_table_options()
	for k in opts:
		var opt = opts[k]
		if not (opts[k] is Tables.W4RMTable.TableReference):
			continue
		out.append(get_create_foreign_key(p_table.get_table_name(), k, opt.schema, opt.table, opt.id))
	return out


static func get_create_table_rls_policies(p_table) -> Array:
	var out = []
	if p_table.security_policies.size() > 0:
		out.append("""
		ALTER TABLE %s ENABLE ROW LEVEL SECURITY;
		""" % sql_identifier(p_table.get_table_name()))
	for k in p_table.security_policies:
		out.append(get_create_table_rls_policy(p_table.get_table_name(), k, p_table.security_policies[k]))
	return out


static func get_create_table_rls_policy(p_table: String, p_policy_name: String, p_policy) -> String:
	var expressions := []
	if p_policy.using != "":
		expressions.append("\t\tUSING (%s)" % p_policy.using)
	if p_policy.with_check != "":
		expressions.append("\t\tWITH CHECK (%s)" % p_policy.with_check)
	return """
		DROP POLICY IF EXISTS %s ON %s;
		CREATE POLICY %s ON %s
		AS %s
		FOR %s
		TO %s%s;
	""" % [
		sql_identifier(p_policy_name),
		sql_identifier(p_table),
		sql_identifier(p_policy_name),
		sql_identifier(p_table),
		Tables.W4RMSecurityPolicyType.keys()[p_policy.type],
		Tables.W4RMCommand.keys()[p_policy.command],
		", ".join(p_policy.roles),
		"\n" + "\n".join(expressions),
	]

static func get_create_table_column_triggers(p_table) -> Array:
	var out = []
	var opts = p_table.get_table_options()
	for k in opts:
		var opt = opts[k]
		if opt.before_update != "":
			out.append(get_create_table_column_trigger(p_table.get_table_name(), k, "BEFORE UPDATE", opt.before_update))
		if opt.after_update != "":
			out.append(get_create_table_column_trigger(p_table.get_table_name(), k, "AFTER UPDATE", opt.after_update))
	return out


static func get_create_table_column_trigger(p_table: String, p_column: String, p_trigger_type: String, p_trigger: String):
	var name = "%s_%s_%s_trigger" % [p_table, p_column, p_trigger_type.replace(' ', '_').to_lower()]
	return """
		CREATE OR REPLACE FUNCTION %s() RETURNS TRIGGER LANGUAGE plpgsql
		AS $BODY$
		BEGIN
		%s
		END;
		$BODY$;

		CREATE OR REPLACE TRIGGER %s
		%s OF %s ON %s
		FOR EACH ROW
		EXECUTE FUNCTION %s();
	""" % [
		name,
		p_trigger,
		name,
		p_trigger_type,
		p_column,
		sql_identifier(p_table),
		name,
	]


static func get_create_table_triggers(p_table) -> Array:
	var out = []
	var triggers: Dictionary = p_table.get_table_triggers()
	for trigger_type in triggers:
		if not VALID_TRIGGER_TYPES.has(trigger_type):
			continue
		out.append(get_create_table_trigger(p_table.get_table_name(), VALID_TRIGGER_TYPES[trigger_type], triggers[trigger_type]))

	return out


static func get_create_table_trigger(p_table: String, p_trigger_type: String, p_trigger: String):
	var name = "%s_%s_trigger" % [p_table, p_trigger_type.replace(' ', '_').to_lower()]
	return """
		CREATE OR REPLACE FUNCTION %s() RETURNS TRIGGER LANGUAGE plpgsql
		AS $BODY$
		BEGIN
		%s
		END;
		$BODY$;

		CREATE OR REPLACE TRIGGER %s
		%s ON %s
		FOR EACH ROW
		EXECUTE FUNCTION %s();
	""" % [
		name,
		p_trigger,
		name,
		p_trigger_type,
		sql_identifier(p_table),
		name,
	]


static func get_drop_tables(p_tables: Array, p_cascade:=false) -> String:
	return """
	BEGIN;
		SET CONSTRAINTS ALL DEFERRED;
		%s
		DROP TABLE IF EXISTS %s %s;
	END;
	""" % [
		"\n\t\t".join(p_tables.map(func (t): return get_drop_cast_function(t.get_table_name()))),
		",".join(p_tables.map(func (t): return sql_identifier(t.get_table_name()))),
		"CASCADE" if p_cascade else ""
	]


static func get_create_table_upcast(p_table) -> String:
	var cast := ["$1.*"]
	for i in range(p_table.get_record_members().size() - p_table.get_table_members().size()):
		cast.append("null")
	return """
	create or replace function upcast_%s({{TABLE}})
	returns {{TYPE}}
	language sql
	as $BODY$ SELECT item::{{TYPE}} FROM (SELECT %s) as item $BODY$;
	DO $$ BEGIN
		create cast ({{TABLE}} as {{TYPE}}) with function upcast_%s({{TABLE}}) as assignment;
	EXCEPTION
		WHEN duplicate_object THEN null;
	END $$;
	""".replace(
			"{{TYPE}}", sql_identifier(p_table.get_record_name())
		).replace(
			"{{TABLE}}", sql_identifier(p_table.get_table_name())
		) % [
			p_table.get_table_name(),
			", ".join(cast),
			p_table.get_table_name(),
		]


static func get_drop_table_upcast(p_table, p_cascade:=false) -> String:
	return """
		DROP CAST IF EXISTS (%s as %s) {{CASCADE}};
		DROP FUNCTION IF EXISTS upcast_%s {{CASCADE}};
	""".replace("{{CASCADE}}", "CASCADE" if p_cascade else "") % [
		sql_identifier(p_table.get_table_name()),
		sql_identifier(p_table.get_record_name()),
		p_table.get_table_name(),
	]


static func get_create_operation(p_operation) -> String:
	var args := []
	for a in p_operation.arguments:
		args.append("%s %s" % [sql_identifier("arg%d" % [args.size() + 1]), sql_identifier(a)])
	return """
		CREATE OR REPLACE FUNCTION %s(%s) RETURNS %s LANGUAGE sql
		AS $BODY$
		%s
		$BODY$;
	""" % [
		sql_identifier(p_operation.name),
		", ".join(args),
		sql_type(p_operation.get_return_type()),
		p_operation.body
	]


static func get_drop_operation(p_operation, p_cascade:=false) -> String:
	return """
		DROP FUNCTION IF EXISTS %s(%s) %s;
	""" % [
		sql_identifier(p_operation.name),
		", ".join(p_operation.arguments.map(func(a): return sql_identifier(a))),
		"CASCADE" if p_cascade else "",
	]


static func get_create_table_publication(p_table_name: StringName, p_full: bool,
		p_publication:="supabase_realtime") -> String:
	var out = """
		DO $$ BEGIN
			ALTER PUBLICATION %s ADD TABLE ONLY %s;
		EXCEPTION
			WHEN duplicate_object THEN null;
		END $$;
	""" % [sql_identifier(p_publication), sql_identifier(p_table_name)]
	if p_full:
		out += """
		ALTER TABLE %s REPLICA IDENTITY FULL;
		""" % [sql_identifier(p_table_name)]
	return out


static func get_drop_table_publication(p_table_name: StringName,
		p_publication:="supabase_realtime") -> String:
	return """
		DO $$ BEGIN
			ALTER PUBLICATION %s DROP TABLE ONLY %s;
		EXCEPTION
			WHEN undefined_table THEN null;
			WHEN undefined_object THEN null;
		END $$;
	""" % [sql_identifier(p_publication), sql_identifier(p_table_name)]


static func get_table_id_default_trigger(p_table_id_name: String, p_default: String) -> String:
	return """
		IF NEW."%s" IS NULL THEN
			NEW."%s" := %s;
		END IF;
		""" % [p_table_id_name, p_table_id_name, p_default]
