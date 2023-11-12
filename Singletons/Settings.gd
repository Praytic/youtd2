extends Node


# Allows getting and setting persistent settings. Inteded to
# be used by settings which are editable by the player
# ingame. Settings are saved to a file on hard drive. Note
# that this is different from Config which doesn't persist
# changes. For example, on Windows the path would be:
# %appdata%/Roaming/Godot/...

const SETTINGS_PATH: String = "user://settings.save"

# List of setting names
const SHOW_OLD_ITEM_NAMES: String = "show_old_item_names"
const SHOW_ALL_DAMAGE_NUMBERS: String = "show_all_damage_numbers"
const ENABLE_SFX: String = "enable_sfx"
const ENABLE_UNRELEASED_TOWERS: String = "enable_unreleased_towers"
const MOUSE_SCROLL: String = "mouse_scroll"
const KEYBOARD_SCROLL: String = "keyboard_scroll"
const ENABLE_MOUSE_SCROLL: String = "enable_mouse_scroll"


var _cache: Dictionary = {}
var _default_value_map: Dictionary = {
	SHOW_OLD_ITEM_NAMES: false,
	SHOW_ALL_DAMAGE_NUMBERS: false,
	ENABLE_SFX: true,
	ENABLE_UNRELEASED_TOWERS: false,
	MOUSE_SCROLL: 0.5,
	KEYBOARD_SCROLL: 0.5,
	ENABLE_MOUSE_SCROLL: true,
}


func _ready():
	var settings_file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)

	if settings_file != null:
		var cache_string: String = settings_file.get_as_text()
		_cache = JSON.parse_string(cache_string) as Dictionary
		
		print_verbose("Opened settings file at path:", settings_file.get_path_absolute())
	else:
		var open_error: Error = FileAccess.get_open_error()
		if open_error == Error.ERR_FILE_NOT_FOUND:
			print_verbose("No settings file found. Will create new one from scratch.")
		else:
			push_error("Failed to open settings file. Error:", error_string(open_error))

		_cache = _default_value_map
#		NOTE: save defaults to file to create settings file for the first time
		flush()


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
