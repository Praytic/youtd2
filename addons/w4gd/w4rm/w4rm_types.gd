extends RefCounted


class W4RMType:
	var name := &""
	var gd_type : int
	var _to_sql := Callable()
	var _to_gd := Callable()

	func map(p_types: Dictionary):
		pass


	func to_sql(val):
		if gd_type == TYPE_OBJECT and typeof(val) == TYPE_NIL:
			return null
		return _to_sql.call(val)


	func to_gd(val, out=null):
		if gd_type == TYPE_OBJECT and typeof(val) == TYPE_NIL:
			return null
		return _to_gd.call(val, out)


	func copy(p_from, p_to=null):
		return to_gd(to_sql(p_from), p_to)


class W4RMBaseType extends W4RMType:
	pass


class W4RMCompositeType extends W4RMType:
	var members : Dictionary
	var make_base : Callable
	var _members_ids : Dictionary


	func get_members_types() -> Dictionary:
		var out = {}
		for k in _members_ids:
			out[k] = instance_from_id(_members_ids[k])
		return out


	func map(p_types: Dictionary):
		var types = {}
		for k in members:
			types[k] = p_types[members[k]]
			_members_ids[k] = types[k].get_instance_id()
		_to_sql = (func(val):
			var out = {}
			for k in types:
				out[k] = types[k].to_sql(val[k])
			return out)
		_to_gd = (func(val, out=null):
			if typeof(out) == TYPE_NIL:
				out = make_base.call()
			for k in types:
				var t = types[k]
				out[k] = types[k].to_gd(val.get(k), out[k])
			return out)


class W4RMArrayType extends W4RMType:
	var base_type_name := &""

	func map(p_types: Dictionary):
		var type = p_types[base_type_name]
		_to_sql = func(val): return val.map(func(e): return type.to_sql(e))
		_to_gd = func(val, out=null):
			if typeof(val) == TYPE_NIL:
				return []
			return val.map(func(e): return type.to_gd(e))



class W4RMMapType extends W4RMType:
	var base_type_name := &""
	var id_type_name := &""

	func map(p_types: Dictionary):
		var type = p_types[base_type_name]
		var id_type = p_types[id_type_name]
		_to_sql = (func(val):
			var out = []
			for k in val:
				out.append(type.to_sql(val[k]))
			return out)
		_to_gd = (func(val, out:={}):
			if typeof(val) == TYPE_NIL:
				out.clear()
				return out
			var keys = val.map(func(e): return e["id"])
			var removed = out.keys().filter(func(k): id_type.to_sql(k) not in keys)
			for k in removed:
				out.erase(k)
			for v in val:
				var k = v["id"]
				var id = id_type.to_gd(k)
				out[id] = type.to_gd(v, out.get(id))
			return out)


class W4RMTableType extends W4RMCompositeType:
	var id_name := &""

	func get_id_type_name() -> StringName:
		return members[id_name]


static func w4rm_type(p_name: StringName, p_gd_type: int, p_to_sql: Callable, p_to_gd: Callable):
	var type = W4RMType.new()
	type.name = p_name
	type.gd_type = p_gd_type
	type._to_gd = p_to_gd
	type._to_sql = p_to_sql
	return type


static func w4rm_base_type(p_name: StringName, p_gd_type: int, p_to_sql: Callable, p_to_gd: Callable):
	var type = W4RMBaseType.new()
	type.name = p_name
	type.gd_type = p_gd_type
	type._to_gd = p_to_gd
	type._to_sql = p_to_sql
	return type


static func w4rm_composite_type(p_name: StringName, p_gd_type: int, p_members: Dictionary, p_make_base: Callable):
	var type = W4RMCompositeType.new()
	type.name = p_name
	type.gd_type = p_gd_type
	type.members = p_members
	type.make_base = p_make_base
	return type


static func w4rm_composite_type_from_schema(p_name: StringName, p_schema: Script, p_base = null):
	var base = p_base
	if base == null:
		base = p_schema
	return w4rm_composite_type(
		p_name, TYPE_OBJECT, get_members_from_schema(p_schema), func(): return base.new())


static func w4rm_array_type(p_name: StringName, base_type_name: StringName):
	var type = W4RMArrayType.new()
	type.name = p_name
	type.gd_type = TYPE_ARRAY
	type.base_type_name = base_type_name
	return type


static func w4rm_map_type(p_name: StringName, base_type_name: StringName, p_id_type: StringName):
	var type = W4RMMapType.new()
	type.name = p_name
	type.gd_type = TYPE_DICTIONARY
	type.base_type_name = base_type_name
	type.id_type_name = p_id_type
	return type


static func w4rm_table_type(p_name: StringName, p_members: Dictionary, p_make_base: Callable, p_id_name:=&"id"):
	var type = W4RMTableType.new()
	type.name = p_name
	type.gd_type = TYPE_OBJECT
	type.members = p_members
	type.make_base = p_make_base
	type.id_name = p_id_name
	return type


static func mktypes():
	var bool2sql = func(val): return bool(val)
	var bool2gd = func(val, _out=null): return bool(val)
	var int2sql = func(val): return int(val)
	var int2gd = func(val, _out=null): return int(val)
	var real2sql = func(val): return float(val)
	var real2gd = func(val, _out=null): return float(val)
	var string2sql = func(val): return str(val)
	var string2gd = func(val, _out=null): return str(val)
	var uuid2sql = func(val): return str(val) if val != &"" else null
	var uuid2gd = func(val, _out=null): return &"" if typeof(val) == TYPE_NIL else StringName(val)
	var dict2sql = func(val): return val
	var dict2gd = func(val, _out=null): return val

	return [
		w4rm_base_type(&"bool", TYPE_BOOL, bool2sql, bool2gd),
		w4rm_base_type(&"int8", TYPE_INT, int2sql, int2gd),
		w4rm_base_type(&"float8", TYPE_FLOAT, real2sql, real2gd),
		w4rm_base_type(&"text", TYPE_STRING, string2sql, string2gd),
		w4rm_base_type(&"timestamp", TYPE_STRING, string2sql, string2gd),
		w4rm_base_type(&"varchar(256)", TYPE_STRING, string2sql, string2gd),
		w4rm_base_type(&"uuid", TYPE_STRING_NAME, uuid2sql, uuid2gd),
		w4rm_base_type(&"jsonb", TYPE_DICTIONARY, dict2sql, dict2gd),
		w4rm_composite_type(&"gdvector2", TYPE_VECTOR2,
			{&"x": &"float8", &"y": &"float8"}, func(): return Vector2()),
		w4rm_composite_type(&"gdvector2i", TYPE_VECTOR2I,
			{&"x": &"int8", &"y": &"int8"}, func(): return Vector2i()),
		w4rm_composite_type(&"gdvector3", TYPE_VECTOR3,
			{&"x": &"float8", &"y": &"float8", "z": &"float8"}, func(): return Vector3()),
		w4rm_composite_type(&"gdvector3i", TYPE_VECTOR3I,
			{&"x": &"int8", &"y": &"int8", "z": &"int8"}, func(): return Vector3i()),
		w4rm_composite_type(&"gdquaternion", TYPE_QUATERNION,
			{&"x": &"float8", &"y": &"float8", "z": &"float8", "w": "float8"}, func(): return Quaternion()),
		w4rm_composite_type(&"gdcolor", TYPE_COLOR,
			{&"r": &"float8", &"g": &"float8", "b": &"float8", "a": "float8"}, func(): return Color()),
	]


static func get_default_type(p_type: int) -> StringName:
	match p_type:
		TYPE_BOOL: return &"bool"
		TYPE_INT: return &"int8"
		TYPE_FLOAT: return &"float8"
		TYPE_STRING: return &"varchar(256)"
		TYPE_STRING_NAME: return &"uuid"
		TYPE_DICTIONARY: return &"jsonb"
		TYPE_VECTOR2: return &"gdvector2"
		TYPE_VECTOR2I: return &"gdvector2i"
		TYPE_VECTOR3: return &"gdvector3"
		TYPE_VECTOR3I: return &"gdvector3i"
		TYPE_QUATERNION: return &"gdquaternion"
		TYPE_COLOR: return &"gdcolor"
	return &""


static func get_members_from_schema(p_schema : Script) -> Dictionary:
	var out := {}
	var started := false
	for p in p_schema.get_script_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		# Parse default value from schema object
		out[p.name] = get_default_type(p.type)
	# TODO this is missing in godot.
	var has_members_override = "_w4rm_members" in p_schema.get_script_method_list().map(func(v): return v.name)
	if has_members_override:
		p_schema.call("_w4rm_members", out)
	return out
