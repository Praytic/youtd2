## Maps tables in the database to GDScript classes.
extends RefCounted

const Types = preload("w4rm_types.gd")
const Tables = preload("w4rm_table.gd")
const Operations = preload("w4rm_operations.gd")
const Watcher = preload("w4rm_watcher.gd")
const SQL = preload("w4rm_sql.gd")

# A simple logger interface
class Log:
	func debug(msg): print_verbose(msg)
	func warning(msg): push_warning(msg)
	func error(msg): push_error(msg)


var _done := false

var logger = Log.new()
var connector = null
var client :
	get:
		return connector.client if connector != null else null

var state := {
	"types": {},
	"composites": {},
	"tables": {},
	"extended": {},
	"operations": {},
	"proxies": {},
	"published": {},
}


func _arr_type(p_base):
	return Types.w4rm_array_type(StringName(str(p_base.name) + "[]"), p_base.name)


func _map_type(p_type, p_id_type_name):
	var tname = p_type.name
	var name = StringName("map{%s}{%s}" % [str(p_id_type_name), str(tname)])
	return Types.w4rm_map_type(name, tname, p_id_type_name)


func _init(p_connector=null):
	var base_types = Types.mktypes()
	for t in base_types:
		state.types[t.name] = t
		var arr_t = _arr_type(t)
		state.types[arr_t.name] = arr_t
		if t is Types.W4RMCompositeType:
			state.composites[t.name] = t
	connector = p_connector


## Adds a composite database type based on a GDScript class.
func add_type(p_name: StringName, p_schema: Script, p_base=null):
	var type = Types.w4rm_composite_type_from_schema(p_name, p_schema, p_base)
	_add_type(type)
	_add_type(_arr_type(type))
	state.composites[type.name] = type
	return type


func _add_type(p_type):
	state.types[p_type.name] = p_type


## Adds a table based on a GDScript class.
func add_table(p_name: StringName, p_schema: Script, p_base=null):
	var base = p_base
	if base == null:
		base = p_schema
	var table = Tables.w4rm_table_from_schema(p_name, p_schema, base)
	_add_type(table.table_type)
	_add_type(table.full_type)
	_add_type(_arr_type(table.table_type))
	_add_type(_map_type(table.table_type, table.table_type.get_id_type_name()))
	_add_type(_arr_type(table.full_type))
	_add_type(_map_type(table.full_type, table.table_type.get_id_type_name()))
	_add_default_table_operations(table)
	state.tables[table.table_type.name] = table
	state.extended[table.full_type.name] = table.full_type
	state.proxies[base.get_instance_id()] = table
	return table


func _add_operation(p_operation):
	state.operations[p_operation.name] = p_operation


## Adds a function that will be stored in the database.
func add_operation(p_name: StringName, p_arguments: Array, p_returns: StringName, p_body:="", p_language:=&"sql"):
	_add_operation(Operations.w4rm_operation(p_name, p_arguments, p_returns, p_body, p_language))


func _add_default_table_operations(p_table):
	for op in Operations.w4rm_table_operations(p_table):
		_add_operation(op)
	for op in Operations.w4rm_table_ref_operations(p_table):
		_add_operation(op)


## Mark this GDScript class so that it will publish realtime database changes (which can be monitored via [method create_watcher] or ["addons/w4gd/supabase/realtime.gd"]).
func publish(p_script: Script, p_full:=false):
	var table = state.proxies[p_script.get_instance_id()]
	state.published[table.get_table_name()] = p_full


## Tells the mapper that we're done setting up our types, tables and operations.
func done():
	_done = true
	for t in state.types.values():
		t.map(state.types)
	for op in state.operations.values():
		op.map(state.types)


## Updates the database based on the types, tables and operations that have been added to the mapper.
func init_db(p_opts:={}) -> bool:
	if not _done:
		done()
	var safe_drop = p_opts.get("safe_drop", true)
	if safe_drop:
		logger.debug("Performing drop")
		var drop = drop_sql(p_opts)
		var res = await connector.query(drop)
		if res.is_error():
			logger.error("Error dropping database %s" % [res])
			logger.error(drop)
			return false
	var do_create = p_opts.get("create", true)
	if do_create:
		logger.debug("Performing create")
		var create = generate_sql()
		var res = await connector.query(create)
		if res.is_error():
			logger.error("Error creating database %s" % [res])
			logger.error(create)
			return false
	logger.debug("Done initializing DB.")
	return true


## Generates SQL to create all the types, tables and operations that have been added to the mapper.
func generate_sql() -> String:
	var queries = []
	# Godot composites
	for type in state.composites.values():
		queries.append(SQL.get_create_type(type))
	# Tables
	for table in state.tables.values():
		queries.append(SQL.get_create_table(table))
	# Create foreign keys
	for table in state.tables.values():
		queries.append_array(SQL.get_create_table_foreign_keys(table))
	# Create RLS policies.
	for table in state.tables.values():
		queries.append_array(SQL.get_create_table_rls_policies(table))
	# Create table column triggers
	for table in state.tables.values():
		queries.append_array(SQL.get_create_table_column_triggers(table))
	# Create table triggers.
	for table in state.tables.values():
		queries.append_array(SQL.get_create_table_triggers(table))
	# Extended table types
	for type in state.extended.values():
		queries.append(SQL.get_create_type(type))
	# Tables upcast
	for table in state.tables.values():
		queries.append(SQL.get_create_table_upcast(table))
	# Create operations
	for operation in state.operations.values():
		# Skip empty operations
		if operation.body.is_empty():
			continue
		queries.append(SQL.get_create_operation(operation))
	# Create publications
	for k in state.published:
		queries.append(SQL.get_create_table_publication(k, state.published[k]))
	return SQL.make_transaction(queries)


## Generates the SQL to drop all the types, tables and operations that have been added to the mapper.
func drop_sql(p_opts:={}):
	var cascade = p_opts.get("cascade", false)
	var op_cascade = p_opts.get("op_cascade", cascade)
	var ex_cascade = p_opts.get("type_cascade", cascade)
	var table_cascade = p_opts.get("table_cascade", cascade)
	var drop_data = p_opts.get("drop_data", false)
	var queries = []
	# Drop publications
	for k in state.published:
		queries.append(SQL.get_drop_table_publication(k))
	# Drop operations
	for op in state.operations.values():
		queries.append(SQL.get_drop_operation(op, op_cascade))
	# Tables upcast
	for table in state.tables.values():
		queries.append(SQL.get_drop_table_upcast(table))
	# Drop extended types
	var extended = state.extended.values()
	extended.reverse()
	for type in extended:
		queries.append(SQL.get_drop_type(type.name, ex_cascade))
	if drop_data:
		# Drop tables
		queries.append(SQL.get_drop_tables(state.tables.values(), table_cascade))
		var composites = state.composites.values()
		composites.reverse()
		for type in composites:
			queries.append(SQL.get_drop_type(type.name, cascade))
	return SQL.make_transaction(queries)


## Gets an "operation proxy" that can be used to call operations in the database.
func op(p_base=null):
	return Operations.w4rm_operation_proxy(self, p_base)


## Creates a record in the database based on the given GDScript object.
func create(p_obj):
	return await (op(p_obj)[state.proxies[p_obj.get_script().get_instance_id()].get_operations_prefix() + "_create"].call([p_obj])) != null


## Gets all records in the database for the given GDScript class, as instances of that class.
func get_all(p_base: GDScript):
	return await (op()[state.proxies[p_base.get_instance_id()].get_operations_prefix() + "_get_all"].call([]))


## Gets a record in the database for the given GDScript class (identified by its id) as an instance of that class.
func get_by_id(p_base: GDScript, p_id):
	return await (op()[state.proxies[p_base.get_instance_id()].get_operations_prefix() + "_by_id"].call([p_id]))


## Updates a record in the database based on the given GDScript object.
func update(p_obj):
	return await (op(p_obj)[state.proxies[p_obj.get_script().get_instance_id()].get_operations_prefix() + "_update"].call([p_obj])) != null


## Refreshes the given GDScript object with the current record stored in the database.
func refresh(p_obj):
	return await (op(p_obj)[state.proxies[p_obj.get_script().get_instance_id()].get_operations_prefix() + "_by_id"].call([p_obj.id]))


## Deletes a record in the database based on the given GDScript object.
func delete(p_obj):
	return await (op(p_obj)[state.proxies[p_obj.get_script().get_instance_id()].get_operations_prefix() + "_delete"].call([p_obj.id])) != null


## Copies the W4RM definition from one GDScript class to another.
func copy(p_from, p_to, p_type=null):
	var type_name = p_type
	if type_name == null:
		type_name = state.proxies[p_from.get_script().get_instance_id()].get_record_name()
	var type = state.types[type_name]
	return type.copy(p_from, p_to)


## Parses the given data into an object of the requested GDScript class.
func parse(p_data, p_to):
	var base = null
	var type_name = p_to
	if typeof(p_to) == TYPE_OBJECT:
		if p_to is Script:
			type_name = state.proxies[p_to.get_instance_id()].get_record_name()
			base = p_to.new()
		else:
			type_name = state.proxies[p_to.get_script().get_instance_id()].get_record_name()
			base = p_to
	var type = state.types[type_name]
	return type.to_gd(p_data, base)


## Converts an instance of a mapped GDScript class into JSON to send to Supabase.
func to_json(p_obj):
	var type_name = state.proxies[p_obj.get_script().get_instance_id()].get_record_name()
	var type = state.types[type_name]
	return type.to_sql(p_obj)


## Creates a watcher object to watch for changes to the database table mapped to the given GDScript class.
func create_watcher(p_schema: GDScript, p_inserted: Callable, p_updated: Callable, p_delete: Callable, p_cond:=""):
	var id = p_schema.get_instance_id()
	if id not in state.proxies:
		logger.error("No table found to watch")
		return null
	var table = state.proxies[id]
	var tname = table.get_table_name()
	if tname not in state.published:
		logger.error("Table %s is not published. Watchers would not work." % [tname])
		return null
	var watcher = Watcher.new()
	var ch = connector.channel(table.get_table_name(), p_cond)
	var is_full = state.published[tname]
	var idconv = state.types[table.get_table_id_type_name()]
	var idname = table.get_table_id_name()
	watcher.watch(
		ch,
		(func (e):
			if p_inserted.is_valid():
				p_inserted.call(parse(e.record, p_schema)))
		,
		(func (e):
			if p_updated.is_valid():
				# Only ID is returned as old record if full replication is off.
				var arg = parse(e.old_record, p_schema) if is_full else idconv.to_gd(e.old_record[idname])
				p_updated.call(parse(e.record, p_schema), arg))
		,
		(func (e):
			if p_delete.is_valid():
				p_delete.call(parse(e.old_record, p_schema)))
	)
	return watcher
