extends Node

const SupabaseClient = preload("../../supabase/client.gd")

class MappableOther:
	var id : StringName
	var some_auto : StringName
	var some_int := 2
	var some_dict := {"asd": 2}


	static func _w4rm_type_options(opts):
		opts["some_auto"] = W4RM.tref("auth.users", {
			unique = true,
			default = "auth.uid()",
			external = true
		})


class Mappable:
	var id : StringName
	var name : String
	var some_bool : bool
	var some_int : int
	var some_float : float
	var some_ref : StringName
	var some_custom := Vector2i(15, 20)
	var time : String = Time.get_datetime_string_from_system(true)


	static func _w4rm_members(members):
		members["time"] = &"timestamp"


	static func _w4rm_type_options(opts):
		opts["id"] = W4RM.option({
			default = "auth.uid()",
			unique = true,
		})
		opts["some_ref"] = W4RM.tref("MappableOther", {
			nullable = true
		})


# Script to create the database runnable via the W4 editor plugin.
static func run_static(sdk: W4Client):
	sdk.mapper.add_table("MappableOther", MappableOther)
	sdk.mapper.add_table("Custom", Mappable)
	var okay = await sdk.mapper.init_db()
	if okay:
		sdk.debug("Succesfully initialized DB.")
	else:
		sdk.error("Failed to initialize DB.")


# Always keep a reference of the mapper
var mapper = W4GD.mapper


func _ready():
	# Map a table
	mapper.add_table("MappableOther", MappableOther)
	# With a custom name
	mapper.add_table("Custom", Mappable)
	# Signal we are done
	mapper.done()
	# Login the client
	var logged = await mapper.client.auth.login_email("ci-test@w4games.com", "password").async()
	if logged.is_error():
		print("Trying to signup")
		var signup = await mapper.client.auth.signup_email("ci-test@w4games.com", "password").async()
		if signup.is_error():
			print("Failed to signup")
			return
		await mapper.client.auth.login_email("ci-test@w4games.com", "password").async()

	# Get all object in the given table.
	var objs = await mapper.get_all(Mappable)
	print(objs)
	if objs.size() > 0:
		# Delete the first object if found.
		await mapper.delete(objs[0])
	# Create a new object
	var obj = Mappable.new()
	var res = await mapper.create(obj)
	if not res:
		push_error("Create failed.")
		return
	# Update an object on the DB
	obj.some_custom.x = 5
	res = await mapper.update(obj)
	# Sync an object from the DB
	obj.some_custom.x = 10
	obj.time = Time.get_datetime_string_from_system(true)
	# Will be 10
	print(obj.some_custom.x)
	print(obj.time)
	res = await mapper.refresh(obj)
	if res:
		# Will be 5 again.
		print(obj.some_custom.x)
		print(obj.time)
