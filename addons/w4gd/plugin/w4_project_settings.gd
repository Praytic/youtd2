@tool
extends RefCounted

static func _add_project_setting(name: String, type: int, default, hint = null, hint_string = null) -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default)

	ProjectSettings.set_initial_value(name, default)

	var info := {
		name = name,
		type = type,
	}
	if hint != null:
		info['hint'] = hint
	if hint_string != null:
		info['hint_string'] = hint_string

	ProjectSettings.add_property_info(info)

static func add_project_settings() -> void:
	_add_project_setting('w4games/w4rm/url', TYPE_STRING, "")
	_add_project_setting('w4games/w4rm/key', TYPE_STRING, "")

	_add_project_setting('w4games/analytics/auto_clean_up_on_quit', TYPE_BOOL, true)

	_add_project_setting('w4games/game_server/enabled', TYPE_BOOL, false)
	_add_project_setting('w4games/game_server/default_port', TYPE_INT, 4343)
	_add_project_setting('w4games/game_server/health_check_interval', TYPE_FLOAT, 2.0, PROPERTY_HINT_RANGE, "0.1,4096,0.1,or_greater,exp,suffix:s")
	_add_project_setting('w4games/game_server/player_join_timeout', TYPE_FLOAT, 30.0, PROPERTY_HINT_RANGE, "0.1,4096,0.1,or_greater,exp,suffix:s")
	_add_project_setting('w4games/game_server/minimum_players', TYPE_INT, 1, PROPERTY_HINT_RANGE, "1,100,1,or_greater")
	_add_project_setting('w4games/game_server/auto_shutdown_on_match_failure', TYPE_BOOL, true)

static func get_config() -> Dictionary:
	var url = OS.get_environment("W4_URL")
	if url == "":
		url = ProjectSettings.get_setting("w4games/w4rm/url")
	var key = OS.get_environment("W4_KEY")
	if key == "":
		key = ProjectSettings.get_setting("w4games/w4rm/key")

	var unsafe_tls := false
	if OS.is_debug_build():
		var ei = OS.get_environment("W4_INSECURE")
		if ei == "1":
			unsafe_tls = true
	return {
		"url": url,
		"key": key,
		"unsafe_tls": unsafe_tls,
	}


static func has_servers() -> bool:
	return ProjectSettings.get_setting("w4games/game_server/enabled")


static func get_server_default_port() -> int:
	return ProjectSettings.get_setting("w4games/game_server/default_port", 4343)
