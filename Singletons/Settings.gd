extends Node


# Allows getting and setting persistent settings. Inteded to
# be used by settings which are editable by the player
# ingame. Settings are saved to a file on hard drive. Note
# that this is different from Config which doesn't persist
# changes. For example, on Windows the path would be:
# %appdata%/Roaming/Godot/...

signal changed()
signal show_combat_log_changed()
signal interface_size_changed(new_scale: float)

const SETTINGS_PATH: String = "user://settings.save"

# List of setting names
const SHOW_OLD_ITEM_NAMES: String = "show_old_item_names"
const SHOW_ALL_DAMAGE_NUMBERS: String = "show_all_damage_numbers"
const ENABLE_SFX: String = "enable_sfx"
const ENABLE_UNRELEASED_TOWERS: String = "enable_unreleased_towers"
const MOUSE_SCROLL: String = "mouse_scroll"
const KEYBOARD_SCROLL: String = "keyboard_scroll"
const ENABLE_MOUSE_SCROLL: String = "enable_mouse_scroll"
const SHOW_COMBAT_LOG: String = "show_combat_log"
# NOTE: storing x and y separately instead of Vector2
# because Vector2 can't be deserialized from JSON
const COMBAT_LOG_X: String = "combat_log_x"
const COMBAT_LOG_Y: String = "combat_log_y"
const INTERFACE_SIZE: String = "interface_size"
const INTERFACE_SIZE_DICT: Dictionary = {
	"Small": 0.75,
	"Medium": 1.0,
	"Large": 1.25
}


var _cache: Dictionary = {}
var _default_value_map: Dictionary = {
	SHOW_OLD_ITEM_NAMES: false,
	SHOW_ALL_DAMAGE_NUMBERS: false,
	ENABLE_SFX: true,
	ENABLE_UNRELEASED_TOWERS: false,
	MOUSE_SCROLL: 0.5,
	KEYBOARD_SCROLL: 0.5,
	ENABLE_MOUSE_SCROLL: true,
	SHOW_COMBAT_LOG: false,
	COMBAT_LOG_X: 20.0,
	COMBAT_LOG_Y: 600.0,
	INTERFACE_SIZE: "Medium",
}


func _ready():
	var settings_file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)

	if settings_file != null and settings_file.get_length() > 0:
		var cache_string: String = settings_file.get_as_text()
		_cache = JSON.parse_string(cache_string) as Dictionary
		_invalidate_cache()
		
		print_verbose("Opened settings file at path:", settings_file.get_path_absolute())
	else:
		var open_error: Error = FileAccess.get_open_error()
		if open_error == Error.ERR_FILE_NOT_FOUND:
			print_verbose("No settings file found. Will create new one from scratch.")
		else:
			push_error("Failed to open settings file. Error:", error_string(open_error))

		_cache = _default_value_map
#		NOTE: save defaults to file to create settings file for the first time


func get_setting(setting: String) -> Variant:
	if !_default_value_map.has(setting):
		push_error("No such setting exists:" % setting)

		return null

	var default_value: Variant = _default_value_map[setting]
	var value: Variant = _cache.get(setting, default_value)

	return value


func get_bool_setting(setting: String) -> bool:
	var value: bool = get_setting(setting) as bool

	return value


func set_setting(setting: String, value: Variant):
	_cache[setting] = value


# Save all changes to file
func flush():
	var settings_file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	var cache_string: String = JSON.stringify(_cache, "    ")
	settings_file.store_line(cache_string)
	
	changed.emit()
	show_combat_log_changed.emit()
	interface_size_changed.emit(INTERFACE_SIZE_DICT[_cache[INTERFACE_SIZE]])


func _invalidate_cache():
	for _cache_key in _cache.keys():
#		Cache should have comparable types with the default map
		if typeof(_default_value_map[_cache_key]) != typeof(_cache[_cache_key]):
			push_error("Saved setting [%s] has incorrect type. Resetting it to default." % _cache_key)
			_cache[_cache_key] = _default_value_map[_cache_key]
