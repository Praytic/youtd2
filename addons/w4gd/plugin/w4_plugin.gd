@tool
extends EditorPlugin

const BASE = "w4games/w4rm"
const URL = "url"
const KEY = "key"
const PROFILES = "profiles"
const CURRENT_PROFILE = "current"

const W4ProjectSettings = preload("w4_project_settings.gd")

const W4DockScene = preload("w4_dock.tscn")
const W4DockScript = preload("w4_dock.gd")

const W4ServerUploader = preload("w4_server_uploader.tscn")

class W4Debugger extends EditorDebuggerPlugin:

	var run_script_path := ""
	var run_script_data := {}

	func _has_capture(prefix) -> bool:
		return prefix == "w4"


	func _capture(message, data, session_id) -> bool:
		if message == "w4:ready":
			run_script(session_id)
			return true
		return false


	func run_script(session_id):
		if run_script_path.is_empty() or run_script_data.is_empty():
			return
		get_session(session_id).send_message("w4:run", [run_script_path, run_script_data.duplicate()])
		run_script_path = ""
		run_script_data.clear()


func _get_s(key, def=null):
	var fk = "%s/%s" % [BASE, key]
	return ProjectSettings.get_setting(fk) if ProjectSettings.has_setting(fk) else def

func _get_m(key, def=null):
	var es = get_editor_interface().get_editor_settings()
	return es.get_project_metadata("w4games", key, def)

func _set_s(key, value, save=true):
	var fk = "%s/%s" % [BASE, key]
	ProjectSettings.set_setting(fk, value)
	if save:
		ProjectSettings.save()

func _set_m(key, value):
	var es = get_editor_interface().get_editor_settings()
	es.set_project_metadata("w4games", key, value)

func _check_set_metadata(key, value):
	if typeof(_get_m(key)) != typeof(value):
		_set_m(key, value)

func _init_settings():
	W4ProjectSettings.add_project_settings()

	_check_set_metadata(PROFILES, [])
	_check_set_metadata(CURRENT_PROFILE, "default")

func _get_profiles() -> Array:
	var profiles = _get_m(PROFILES, [])
	if typeof(profiles) == TYPE_ARRAY:
		return profiles.duplicate(true)
	return []


func _get_profile(profile_name: String) -> Dictionary:
	if profile_name == "default":
		return {
			"url": _get_s(URL),
			"key": _get_s(KEY),
		}
	var found = _get_profiles().filter(func(p): return p["name"] == profile_name)
	if found.size():
		return found.front()
	return {}


func _set_profiles(profiles: Array):
	for p in profiles:
		if "name" not in p or "url" not in p or "key" not in p:
			push_error("Invalid profile: %s" % [p])
			return
	_set_m(PROFILES, profiles)


func _profile_edited(profile: String, key: String, value: String):
	if profile == "default":
		_set_s(key, value)
	else:
		var profiles := _get_profiles()
		if typeof(profiles) != TYPE_ARRAY:
			profiles = []
		for p in profiles:
			if typeof(p) != TYPE_DICTIONARY:
				continue
			if p.has("name") and p["name"] == profile:
				p[key] = value
				break
		_set_profiles(profiles)
	# Ensure the environment variables are also updated.
	var current = _get_profile(dock.current_profile)
	OS.set_environment("W4_URL", current["url"])
	OS.set_environment("W4_KEY", current["key"])


func _profile_add():
	var profiles := _get_profiles()
	var pname = "Profile"
	var idx = 0
	var names = profiles.map(func(e): return e["name"])
	for i in range(0, 10):
		if (pname + str(i)) not in names:
			pname += str(i)
			break
	if pname == "Profile":
		return
	profiles.append({"name": pname, "url": "", "key": ""})
	_set_profiles(profiles)
	_update_dock()


func _profile_delete(profile: String):
	var profiles : Array = _get_profiles()
	var found = profiles.filter(func(e): return e["name"] == profile)
	if found.size():
		profiles.erase(found.front())
		_set_profiles(profiles)
		if profile == _get_m(CURRENT_PROFILE):
			_set_m(CURRENT_PROFILE, "default")
		_update_dock()


func _profile_renamed(profile: String, to: String):
	var profiles : Array = _get_profiles()
	if to == "default" or profile == "default":
		return
	var found = profiles.filter(func(e): return e["name"] == profile)
	if found.size():
		found.front()["name"] = to
		_set_profiles(profiles)
		if profile == _get_m(CURRENT_PROFILE):
			_set_m(CURRENT_PROFILE, to)
		_update_dock()


func _profile_selected(profile: String):
	var profiles : Array = _get_profiles()
	var found = profiles.filter(func(e): return e["name"] == profile)
	var current := "default"
	if found.size():
		current = profile
	_set_m(CURRENT_PROFILE, current)
	_update_dock()


var debugger : W4Debugger
var dock : Control

func _update_dock():
	if dock == null:
		return
	dock.key = _get_s(KEY)
	dock.url = _get_s(URL)
	dock.profiles = _get_m(PROFILES)
	dock.current_profile = _get_m(CURRENT_PROFILE)
	var current = _get_profile(dock.current_profile)
	OS.set_environment("W4_URL", current["url"])
	OS.set_environment("W4_KEY", current["key"])


func _run_script(profile_name, key, script_path):
	var profile = _get_profile(profile_name)
	if profile.is_empty():
		return
	debugger.run_script_path = script_path
	debugger.run_script_data = {"url": profile["url"], "key": profile["key"], "service_key": key}
	var scene = dock.scene_file_path.get_base_dir() + "/w4_script_loader.tscn"
	get_editor_interface().play_custom_scene(scene)


var server_uploader: Node

func _open_server_uploader() -> void:
	if server_uploader:
		var profile = _get_profile(_get_m(CURRENT_PROFILE))
		if profile.is_empty():
			return
		server_uploader.show_server_uploader(profile)

func _enter_tree():
	_init_settings()

	debugger = W4Debugger.new()
	dock = W4DockScene.instantiate()
	dock.set_script(W4DockScript)
	_update_dock()

	dock.profile_edited.connect(_profile_edited)
	dock.profile_added.connect(_profile_add)
	dock.profile_deleted.connect(_profile_delete)
	dock.profile_renamed.connect(_profile_renamed)
	dock.profile_selected.connect(_profile_selected)
	dock.run_confirmed.connect(_run_script)

	add_debugger_plugin(debugger)
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)

	server_uploader = W4ServerUploader.instantiate()
	get_editor_interface().get_base_control().add_child(server_uploader)
	add_tool_menu_item("Export & Upload Server to W4 Cloud...", self._open_server_uploader)

	add_autoload_singleton("W4GD", "res://addons/w4gd/w4gd.gd")


func _exit_tree():
	remove_control_from_docks(dock)
	remove_debugger_plugin(debugger)
	dock.queue_free()
	dock = null
