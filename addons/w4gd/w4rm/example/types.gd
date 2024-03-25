extends Node

class MyType:
	var some_int := 2
	var some_float := 3.5


	func _to_string():
		return "MyType<some_int=%d, some_float=%f>" % [some_int, some_float]


class MyCollection:
	var id : StringName
	var my_type : MyType = MyType.new()
	var vec : Vector2 = Vector2(10, 1)


	static func _w4rm_members(members):
		members["my_type"] = &"MyType"


	func _to_string():
		return "MyCollection<id=%s, vec=%s, my_type=%s" % [id, vec, my_type]


var mapper = W4RM.mapper(self)

func _ready():
	mapper.add_type("MyType", MyType)
	mapper.add_table("MyCollection", MyCollection)
	mapper.done()

	var table = MyCollection.new()
	await mapper.create(table)
	print(await mapper.get_by_id(MyCollection, table.id))
	table.my_type.some_float = 5.3
	print(await mapper.update(table))
	print(await mapper.get_by_id(MyCollection, table.id))
	var t2 = MyCollection.new()
	mapper.copy(table, t2)
	print(t2)


# Script to create the database runnable via the W4 editor plugin.
static func run_static(sdk: W4Client):
	var mapper = sdk.mapper
	# This gives better logs when run from the plugin
	# mapper.logger = p_node
	mapper.add_type("MyType", MyType)
	mapper.add_table("MyCollection", MyCollection)
	var okay = await mapper.init_db()
	print("Created DB: %s" % okay)
