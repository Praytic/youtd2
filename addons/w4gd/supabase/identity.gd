## Represents a Supabase identity.
##
## This includes the Supabase role (anonymous, authenticated, service_role) and the user ID
## if the client is authenticated with Supabase.
extends RefCounted

const JWTUtils = preload("jwt_utils.gd")

## The API key.
var apikey := ""
## The access token.
var access_token := ""
## The refresher token.
var refresher_token := ""
## The role (anonymous, authenticated or service_role).
var role := ""
## When the current access token expires in UNIX time (seconds since the epoch).
var expire := 0
## The UUID representing the current user in the database (if authenticated).
var uid := StringName()
## The JWT payload from Supabase.
var data := {}

## Emitted when the current identity has changed (logging in, logging out, etc).
signal identity_changed()

func _init(p_apikey: String):
	apikey = p_apikey
	reset_access_token()


func _clear():
	access_token = ""
	refresher_token = ""
	role = ""
	expire = 0
	uid = StringName()
	data.clear()


## Resets the access token to the API key.
func reset_access_token():
	set_access_token(apikey)


## Sets the access token to the given JWT string.
func set_access_token(p_token : String):
	if p_token == access_token:
		return
	_clear()
	var parsed = {} if p_token.is_empty() else JWTUtils.parse_token(p_token)
	if parsed.is_empty():
		identity_changed.emit()
		return
	access_token = p_token
	var header = parsed["header"]
	var payload = parsed["payload"]
	role = payload["role"] if "role" in payload else ""
	expire = payload["exp"] if "exp" in payload else 0
	uid = StringName(payload["sub"]) if "sub" in payload else StringName()
	data = payload.duplicate()
	identity_changed.emit()


## Gets the acccess token.
func get_access_token():
	return access_token


## Gets the API key.
func get_api_key():
	return apikey


## Returns true if the access token is expired; otherwise, false.
func is_expired():
	return expire > Time.get_unix_time_from_system()


## Returns true if the identity is valid; otherwise, false.
func is_valid():
	return role.length() > 0


## Returns true the identity is valid and represents an anonymous user; otherwise, false.
func is_anon():
	return role == "anon"


## Returns true the identity is valid and represents the service role; otherwise, false.
func is_service():
	return role == "service_role"


## Returns true the identity is valid and represents an authenticated user; otherwise, false.
func is_authenticated():
	return role == "authenticated"


## Gets the UUID of the current user in the database (if authenticated).
func get_uid() -> StringName:
	return uid if is_authenticated() else StringName()


## Gets the email address of the current user (if authenticated).
func get_email() -> String:
	return data.get("email", "") if is_authenticated() else ""
