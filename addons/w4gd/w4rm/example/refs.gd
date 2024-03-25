extends Node

class A:
	var id : StringName
	var omg : String
	var ref : Dictionary


	static func _w4rm_type_options(opts):
		opts["ref"] = W4RM.backref("C.a_id", {map=true})


	func _to_string():
		return "A<id=%s, omg=%s, ref=%s>" % [id, omg, ref]


class B:
	var id : StringName
	var lol : String


class C:
	var id : StringName
	var a_id : StringName
	var b_id : StringName
	var omg : Vector2 = Vector2(10, 1)
	var b : B


	static func _w4rm_type_options(opts):
		opts["a_id"] = W4RM.tref("A")
		opts["b_id"] = W4RM.tref("B", {target="b"})


# Script to create the database runnable via the W4 editor plugin.
static func run_static(sdk: W4Client):
	var mapper = sdk.mapper
	mapper.add_table("B", B)
	var c_table = mapper.add_table("C", C)
	var a_table = mapper.add_table("A", A)
	mapper.add_operation("load_C_deep", [c_table.get_table_id_type_name()], c_table.get_record_name(), """
		SELECT *, to_jsonb("C_get_b_id_reference"(id))::"B" as "b" FROM "%s" WHERE id = $1;
	""" % [c_table.get_table_name()])
	mapper.add_operation("load_A_deep", [a_table.get_table_id_type_name()], a_table.get_record_name(), """
		SELECT a.*, array_agg("load_C_deep"(c.id)) as "ref" FROM "%s" as a JOIN "%s" as c ON a.id = c.a_id WHERE a.id = $1 GROUP BY a.id;
	""" % [a_table.get_table_name(), c_table.get_table_name()])
	var okay = await mapper.init_db()
	if okay:
		print("Database initialized")
	else:
		print("Error initializing DB")


var mapper = W4RM.mapper(self)

func _ready():
	mapper.add_table("B", B)
	var c_table = mapper.add_table("C", C)
	var a_table = mapper.add_table("A", A)
	mapper.add_operation("load_C_deep", [c_table.get_table_id_type_name()], c_table.get_record_name())
	mapper.add_operation("load_A_deep", [a_table.get_table_id_type_name()], a_table.get_record_name())
	mapper.done()

	var a = A.new()
	var b = B.new()
	await mapper.create(a)
	await mapper.create(b)
	var c = C.new()
	c.a_id = a.id
	c.b_id = b.id
	await mapper.create(c)
	print(await mapper.op(a).load_A_deep.call([a.id]))
	print(a.ref)
	var bd = null
	if a.ref.is_empty():
		print("error")
		return
	else:
		bd = a.ref.values().front().b
		print(bd)
	print(await mapper.op(a).load_A_deep.call([a.id]))
	print(bd == a.ref.values().front().b)
	var na = A.new()
	mapper.copy(a, na)
	print(na)
	print(await mapper.update(c))
	print("done")
