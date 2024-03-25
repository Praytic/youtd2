extends RefCounted

const Types = preload("w4rm_types.gd")
const Triggers = preload("w4rm_triggers.gd")

enum W4RMCommand {
	ALL,
	SELECT,
	INSERT,
	UPDATE,
	DELETE,
}

enum W4RMSecurityPolicyType {
	PERMISSIVE,
	RESTRICTIVE,
}

class W4RMTable:
	class MemberOption:
		var nullable := false
		var unique := false
		var default := &""
		var before_update := ""
		var after_update := ""


	class TableReference extends MemberOption:
		var name := &""
		var schema := &""
		var table := &""
		var id := &""
		var target := &""
		var external := false


	class TableBackReference extends MemberOption:
		var name := &""
		var schema := &""
		var table := &""
		var column := &""
		var map := false


	class SecurityPolicy:
		var roles : Array
		var type : int
		var command : int
		var using := ""
		var with_check := ""


	var name := &""
	var table_type = null # W4RMTableType
	var full_type = null # W4RMCompositeType
	var options : Dictionary
	var triggers : Dictionary
	var security_policies : Dictionary

	func get_table_name():
		return table_type.name


	func get_record_name():
		return full_type.name


	func get_table_id_name():
		return table_type.id_name


	func get_table_id_type_name():
		return table_type.get_id_type_name()


	func get_table_members():
		return table_type.members


	func get_table_members_types():
		return table_type.get_members_types()


	func get_record_members():
		return full_type.members


	func get_table_options():
		return options


	func get_table_triggers():
		return triggers


	func get_operations_prefix() -> String:
		return str(name)


static func w4rm_table_from_schema(p_name: StringName, p_schema: Script, p_base=null):
	var members := Types.get_members_from_schema(p_schema)
	var options := {}
	var static_methods = p_schema.get_script_method_list().map(func(v): return v.name)
	if "_w4rm_type_options" in static_methods:
		p_schema.call("_w4rm_type_options", options)
	var base = p_base
	if base == null:
		base = p_schema
	var table = w4rm_table_from_dict(p_name, base, members, options)
	if "_w4rm_security_policies" in static_methods:
		p_schema.call("_w4rm_security_policies", table.security_policies)
	if "_w4rm_triggers" in static_methods:
		var tb = Triggers.W4RMTriggerBuilder.new(table)
		p_schema.call("_w4rm_triggers", table.triggers, tb)
		tb.build(table.triggers)
	# If no triggers are given, put defaults on the id column.
	if table.triggers.size() == 0:
		var table_id = table.get_table_id_name()
		var table_id_opt = table.get_table_options().get(table_id)
		var tb = Triggers.W4RMTriggerBuilder.new(table)
		if table_id_opt and table_id_opt.default != &"":
			tb.force_default_on_insert(table_id)
		tb.cannot_update(table_id)
		tb.build(table.triggers)
	return table


static func w4rm_table_from_dict(p_name: StringName, p_base: GDScript, p_fields:={}, p_options:={}, p_security_policies:={}, p_triggers:={}):
	var fields := {}
	var virtuals := []
	for k in p_options:
		var opt = p_options[k]
		if opt is W4RMTable.TableReference:
			if opt.target != &"":
				virtuals.append(str(opt.target))
				p_fields[str(opt.target)] = &"jsonb" if opt.external else opt.table
			if not opt.external:
				opt.table = str(opt.table) + "_table"
		elif opt is W4RMTable.TableBackReference:
			virtuals.append(str(k))
			if opt.map:
				p_fields[k] = "map{uuid}{%s}" % opt.table
			else:
				p_fields[k] = str(opt.table) + "[]"
			opt.table = str(opt.table) + "_table"
	for k in p_fields:
		if str(k) in virtuals:
			continue
		fields[k] = p_fields[k]
	var table = W4RMTable.new()
	table.name = p_name
	table.table_type = Types.w4rm_table_type(StringName(str(p_name) + "_table"), fields, func(): return p_base.new())
	table.full_type = Types.w4rm_composite_type(p_name, TYPE_OBJECT, p_fields, func(): return p_base.new())
	table.options = p_options
	table.security_policies = p_security_policies
	table.triggers = p_triggers
	# Set default options for the table id.
	var table_id = table.get_table_id_name()
	if not table_id in table.options:
		var opt = w4rm_option()
		if table.get_table_id_type_name() == &"uuid":
			opt.default = "extensions.uuid_generate_v4()"
		table.options[table_id] = opt
	return table


static func w4rm_option(opts:={}, p_base=null):
	var base = p_base
	if base == null:
		base = W4RMTable.MemberOption.new()
	base.nullable = opts.get("nullable", false)
	base.unique = opts.get("unique", false)
	base.default = opts.get("default", &"")
	base.before_update = opts.get("before_update", "")
	base.after_update = opts.get("after_update", "")
	return base


static func w4rm_reference(opts:={}):
	var tr = W4RMTable.TableReference.new()
	w4rm_option(opts, tr)
	tr.name = opts.get("name", &"")
	tr.schema = opts.get("schema", &"public")
	tr.table = opts.get("table", &"")
	tr.id = opts.get("id", &"id")
	tr.target = opts.get("target", &"")
	tr.external = opts.get("external", false)
	return tr


static func w4rm_backreference(opts:={}):
	var tr = W4RMTable.TableBackReference.new()
	w4rm_option(opts, tr)
	tr.name = opts.get("name", &"")
	tr.schema = opts.get("schema", &"public")
	tr.table = opts.get("table", &"")
	tr.column = opts.get("column", &"")
	tr.map = opts.get("map", false)
	return tr


static func w4rm_security_policy(opts:={}):
	var sp = W4RMTable.SecurityPolicy.new()

	var roles
	if opts.has('roles'):
		roles = opts['roles']
	elif opts.has('role'):
		roles = opts['role']
	if roles == null:
		roles = ['anon', 'authenticated']
	if not roles is Array:
		roles = [roles]

	sp.roles = roles
	sp.type = opts.get('type', W4RMSecurityPolicyType.PERMISSIVE)
	sp.command = opts.get('command', W4RMCommand.ALL)
	sp.using = opts.get('using', '')
	sp.with_check = opts.get('with_check', '')

	return sp
