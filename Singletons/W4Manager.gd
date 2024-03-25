extends Node


# If there was an error in the last server request, we will save the error message here.
var last_error := ""

# This will return true if there was an error in our last server request.
var has_error := false:
	get:
		return last_error != ""


func _ready():
	setup_mapper(W4GD.mapper)


func login() -> bool:
	# In case there was an error previously, we clear it.
	last_error = ""
	# We make an authentication request to W4 Cloud and wait for the result.
	var login_result = await W4GD.auth.login_device_auto().async()
	# We check for errors; if there's any, we store the error message.
	if login_result.is_error():
		last_error = login_result.as_error().message
		EventBus.login_failed.emit()
		return false
	else:
		EventBus.login_succeeded.emit()
		return true


## Represents a player's profile as stored in the database.
class Profile:

	## A static and unique id for the player. The StringName type gets converted to an index in the SQL database.
	## This is a foreign key towards `users.uid`
	var id: StringName
	## The username entered by the player.
	var username: String

	# Called by the W4 mapper to set specific column options in the SQL database.
	static func _w4rm_type_options(opts: Dictionary) -> void:
		opts["id"] = W4RM.tref("auth.users", {
			default = "auth.uid()",
			external = true,
		})

	# Called by the W4 mapper to set specific column policies in the SQL database.
	static func _w4rm_security_policies(policies: Dictionary) -> void:
		policies["Anyone can view profiles"] = W4RM.build_security_policy_for(['anon', 'authenticated']).can_select()
		policies["User can create own profile"] = W4RM.build_security_policy_for('authenticated').owner_can_insert('id')
		policies["User can update own profile"] = W4RM.build_security_policy_for('authenticated').owner_can_update('id')

## Appends custom types and tables to the mapper so it can be used throughout
## the application. Run this once before using any database call.
func setup_mapper(mapper) -> void:
	mapper.add_table("Profile", Profile)
	mapper.done()

## Creates the table on W4 cloud's database.
##
## Run this function once through the W4 dock in the Godot editor to create a
## table on the remote W4 database. It ensures all tables in the mapper get
## created.
## If the table already exists, it will be dropped first and recreated from
## scratch.
func run_static(sdk) -> void:
	setup_mapper(sdk.mapper)
	var okay = await sdk.mapper.init_db()
	print("Created DB: %s" % okay)


## Returns a username for a given user id.
##
## Returns name_if_unknown if the player was not found.
func get_username(id: String = "", name_if_unknown := "UnknownPlayer") -> String:
	if id == "":
		id = W4GD.get_identity().get_uid()
	var profile: Profile = await W4GD.mapper.get_by_id(Profile, id)
	if profile == null:
		return name_if_unknown
	return profile.username


## Updates or creates a new profile in the database.
##
## If there was no profile associated with the currently logged-in user, this
## will create a new one.
## If a profile existed, this will update the username.
## If the username is unchanged from its previous state, nothing will happen.
func set_own_username(new_username: String) -> void:
	var profile = Profile.new()
	profile.username = new_username
	var res = await W4GD.mapper.create(profile)
	if not res:
		push_error("Player profile creation failed for username: %s" % new_username)
		return
