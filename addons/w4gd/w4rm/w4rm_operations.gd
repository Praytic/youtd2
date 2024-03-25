extends RefCounted

const Tables = preload("w4rm_table.gd")
const Types = preload("w4rm_types.gd")

class W4RMOperation:
	var name := &""
	var arguments := []
	var language := &""
	var returns := &""
	var body := ""

	var _returns = 0

	func map(p_types):
		_returns = p_types[returns].get_instance_id()


	func get_return_type():
		return instance_from_id(_returns)


class W4RMOperationProxy:
	var mapper = null
	var base = null

	func _get(property):
		if property not in mapper.state.operations:
			mapper.logger.error("Operation not found: %s" % property)
			return null
		return func(p_args: Array):
			var op = mapper.state.operations[property]
			if p_args.size() != op.arguments.size():
				mapper.logger.error("Operation %s called with %d arguments, expected %d" % [
					property,
					p_args.size(),
					op.arguments.size()
				])
			var args := []
			for i in range(p_args.size()):
				args.append(mapper.state.types[op.arguments[i]].to_sql(p_args[i]))
			var res = await mapper.connector.function(property, args)
			if res.is_error():
				mapper.logger.error(res.get_data())
				return null
			var data = res.get_data()
			var res_type = mapper.state.types[op.returns]
			# Hack! FIXME! How?
			if data == null or 'id' in data and data["id"] == null:
				if res_type is Types.W4RMArrayType:
					return []
				elif res_type is Types.W4RMMapType:
					return {}
				return null
			return res_type.to_gd(res.get_data(), base)


static func w4rm_operation(p_name: StringName, p_arguments: Array, p_returns: StringName, p_body: String, p_language:=&"sql"):
	var op = W4RMOperation.new()
	op.name = p_name
	op.arguments = p_arguments
	op.returns = p_returns
	op.body = p_body
	op.language = p_language
	return op


static func w4rm_table_operations(p_table):
	var prefix = p_table.get_operations_prefix() + "_"
	var table_type_name = p_table.get_table_name()
	var id_name = p_table.get_table_id_name()
	var id_type_name = p_table.get_table_id_type_name()
	var members = p_table.get_table_members().keys()
	return [
		w4rm_operation(prefix + "create", [table_type_name], table_type_name, """
			INSERT INTO "%s" (%s) VALUES (%s) RETURNING *;
		""" % [
			table_type_name,
			", ".join(members.map(func(k): return '"%s"' % k)),
			", ".join(members.map(func(k): return '$1."%s"' % k))
		]),
		w4rm_operation(prefix + "get_all", [], str(table_type_name) + "[]", """
			SELECT coalesce(array_agg(t::"%s"), '{}') from (SELECT * FROM "%s") as t
		""" % [table_type_name, table_type_name]),
		w4rm_operation(prefix + "by_id", [id_type_name], table_type_name, """
			SELECT * FROM "%s" WHERE "%s" = $1;
		""" % [table_type_name, id_name]),
		w4rm_operation(prefix + "update", [table_type_name], table_type_name, """
			UPDATE "%s" SET %s WHERE "%s" = $1.%s RETURNING *;
		""" % [
			table_type_name,
			", ".join(members.filter(func(k): return k != id_name).map(func(k): return '"%s" = $1."%s"' % [k, k])),
			id_name,
			id_name
		]),
		w4rm_operation(prefix + "delete", [id_type_name], table_type_name, """
			DELETE FROM "%s" WHERE "%s" = $1 RETURNING *;
		""" % [table_type_name, id_name]),
	]


static func w4rm_table_ref_operations(p_table):
	var out := []
	var opts = p_table.get_table_options()
	for k in opts:
		var opt = opts[k]
		var prefix = p_table.get_operations_prefix() + "_"
		var id_name = p_table.get_table_id_name()
		var id_type_name = p_table.get_table_id_type_name()
		var members = p_table.get_table_members()
		if opt is Tables.W4RMTable.TableReference:
			if opt.target == &"":
				continue
			var ret = &"jsonb" if opt.external else opt.table
			var tb = '"%s"."%s"' % [opt.schema, opt.table] if opt.schema != StringName() else '"%s"' % opt.table
			var select = "to_jsonb(t.*) result" if opt.external else "*"
			out.append(w4rm_operation(prefix + "get_%s_reference" % k, [id_type_name], ret, """
					SELECT %s FROM %s as t WHERE %s IN (SELECT "%s" FROM "%s"($1));
				""" % [select, tb, opt.id, k, prefix + "by_id"]))
		elif opt is Tables.W4RMTable.TableBackReference:
			var ret_type = str(opt.table) + "[]" if not opt.map else ("map{uuid}{%s}" % [opt.table])
			out.append(
				w4rm_operation(prefix + "get_%s" % k, [id_type_name], ret_type, """
					SELECT coalesce(array_agg(item::"%s"), '{}') FROM (SELECT * FROM "%s" WHERE "%s" = $1) as item;
				""" % [opt.table, opt.table, opt.column])
			)
	return out


static func w4rm_operation_proxy(p_mapper, p_base=null):
	var op = W4RMOperationProxy.new()
	op.mapper = p_mapper
	op.base = p_base
	return op
