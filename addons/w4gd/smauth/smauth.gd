## The W4 Cloud custom authentication end-point at /idp/v1.
extends "../supabase/auth.gd"

const Endpoint = preload("../supabase/endpoint.gd")

## The custom authentication endpoint.
var idp : Endpoint

var _uuid := W4Utils.UUIDGenerator.new()

func _init(client, identity):
	super(client, "/auth/v1", identity)
	idp = Endpoint.new(client, "/idp/v1", identity)


## Login using a device ID and key combination.
##
## Store the ID and key in the client to allow the client to reuse the same player.
##
## [param id] A randomly generated UUIDv4 to use a username.
##
## [param key] A randomly generated string to be use as password for future logins.
func login_device(id: String, key: String):
	return begin_sso(
		"anon.localhost"
	).then(func(result):
		if result.is_error():
			return result
		var split : PackedStringArray = result["url"].as_string().split("?")
		if split.size() < 2:
			return result
		var request_query = client.dict_from_query(split[1])
		return idp.POST("/sso", {
			"provider": "device",
			"id": id,
			"key": key,
		}, request_query)
	).then(func(result):
		if result.is_error():
			return result
		return login_sso(result.as_dict())
	)


## Login using device specific information
func login_device_auto():
	var cfg := ConfigFile.new()
	var file := "user://w4credentials.cfg"
	var section := "w4credentials"
	if FileAccess.file_exists(file):
		cfg.load(file)
	if not cfg.has_section(section) or not cfg.has_section_key(section, "device_id"):
		cfg.set_value(section, "device_id", _uuid.generate_v4())
	if not cfg.has_section(section) or not cfg.has_section_key(section, "device_key"):
		cfg.set_value(section, "device_key", _uuid.generate_v4())
	cfg.save(file)
	return login_device(cfg.get_value(section, "device_id"), cfg.get_value(section, "device_key"))
