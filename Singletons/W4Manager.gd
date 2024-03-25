extends Node


signal last_request_status_updated(status_message: String, is_error: bool)
signal auth_state_changed()

enum State {
	UNAUTHENTICATED,
	LOGGED_IN,
	AUTHENTICATED,
}


var current_state: State = State.UNAUTHENTICATED : set = set_current_state
var current_username: String = "UnknownPlayer"


func _ready():
	setup_mapper(W4GD.mapper)


func login() -> bool:
	# We make an authentication request to W4 Cloud and wait for the result.
	var login_result = await W4GD.auth.login_device_auto().async()
	# We check for errors; if there's any, we store the error message.
	if login_result.is_error():
		return _update_status(login_result.as_error().message, true)
	else:
		set_current_state(State.LOGGED_IN)
		return _update_status("Successfully logged in.")


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
## If a profile existed, this will produce a soft error.
## If the username is unchanged from its previous state, nothing will happen.
func set_own_username(username: String, is_new: bool) -> bool:
	if current_state == State.AUTHENTICATED:
		push_error("Attempted to change username while being authenticated.")
		return false
	
	if current_state == State.UNAUTHENTICATED:
		push_error("Device is not yet registered in W4Cloud. You should log in first.")
		return false
	
	var possible_profile = await get_username()
	
#	Player should log in with the existing profile
	if is_new && possible_profile != "UnknownPlayer":
		return _update_status("You already have a profile. Try to log in as: %s." % possible_profile, true)
	
#	Player should have valid new username
	if !_validate_username(username):
		return _update_status("Please enter valid username." % possible_profile, true)
	
#	Create new profile for a player if none exists in the database
	if is_new:
		var profile = Profile.new()
		profile.username = username
		var res = await W4GD.mapper.create(profile)
		if not res:
			return _update_status("Player profile creation failed for username: %s" % username, true)
	
	set_current_state(State.AUTHENTICATED)
	current_username = username
	return _update_status("Player name: %s" % username)


func _validate_username(username: String) -> bool:
	return username != "UnknownPlayer"


func _update_status(message: String = "", is_error: bool = false) -> bool:
	if is_error:
		push_error(message)
	last_request_status_updated.emit(message, is_error)
	return !is_error


func set_current_state(state: State):
	current_state = state
	auth_state_changed.emit()
