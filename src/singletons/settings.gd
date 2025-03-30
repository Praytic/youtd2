extends Node


# Allows getting and setting persistent settings. Intended
# to be used by settings which are editable by the player
# ingame. Settings are saved to a file on hard drive. For
# example, on Windows the path would be:
# %appdata%/Roaming/Godot/...

signal changed()

const SETTINGS_PATH: String = "user://settings.save"

enum InterfaceSize {
	SMALL,
	MEDIUM,
	LARGE
}

# List of setting names
const SHOW_ALL_DAMAGE_NUMBERS: String = "show_all_damage_numbers"
const ENABLE_FLOATING_TEXT: String = "enable_floating_text"
const ENABLE_VFX: String = "enable_vfx"
const ENABLE_SFX: String = "enable_sfx"
const PROJECTILE_DENSITY: String = "projectile_density"
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
	InterfaceSize.SMALL: 0.75,
	InterfaceSize.MEDIUM: 1.0,
	InterfaceSize.LARGE: 1.25
}
const SHOW_TUTORIAL_ON_START: String = "show_tutorial_on_start"
const CACHED_GAME_DIFFICULTY: String = "CACHED_GAME_DIFFICULTY"
const CACHED_GAME_MODE: String = "CACHED_GAME_MODE"
const CACHED_GAME_LENGTH: String = "CACHED_GAME_LENGTH"
const PLAYER_NAME: String = "PLAYER_NAME"
const EXP_PASSWORD: String = "EXP_PASSWORD"
const WISDOM_UPGRADES_CACHED: String = "WISDOM_UPGRADES_CACHED"
const DISPLAY_MODE: String = "DISPLAY_MODE"
const MISSION_STATUS: String = "MISSION_STATUS"
const SHOWED_ONE_TIME_HELP_POPUP: String = "SHOWED_ONE_TIME_HELP_POPUP"
const LANGUAGE: String = "LANGUAGE"


var _cache: Dictionary = {}


# NOTE: need to convert enum values to floats because JSON
# only supports floats. If we don't do this, then the type
# checking of cache will fail.
var _default_value_map: Dictionary = {
	SHOW_ALL_DAMAGE_NUMBERS: false,
	ENABLE_FLOATING_TEXT: true,
	ENABLE_VFX: true,
	ENABLE_SFX: true,
	PROJECTILE_DENSITY: 1.0,
	MOUSE_SCROLL: 0.5,
	KEYBOARD_SCROLL: 0.5,
	ENABLE_MOUSE_SCROLL: false,
	SHOW_COMBAT_LOG: false,
	COMBAT_LOG_X: 20.0,
	COMBAT_LOG_Y: 600.0,
	INTERFACE_SIZE: InterfaceSize.MEDIUM as float,
	SHOW_TUTORIAL_ON_START: true,
	CACHED_GAME_DIFFICULTY: "beginner",
	CACHED_GAME_MODE: "random_with_upgrades",
	CACHED_GAME_LENGTH: Constants.WAVE_COUNT_TRIAL as float,
	PLAYER_NAME: "Player",
	EXP_PASSWORD: "",
	WISDOM_UPGRADES_CACHED: {},
	DISPLAY_MODE: DisplayMode.enm.FULLSCREEN as float,
	MISSION_STATUS: {},
	SHOWED_ONE_TIME_HELP_POPUP: false,
	LANGUAGE: OS.get_locale_language(),
}


#########################
###     Built-in      ###
#########################

# NOTE: it is intentional that changed() signal is not
# emitted at the end of _ready(). This is because
# Settings._ready() is called before the majority of the
# game nodes are created (Settings is a singleton). Nodes
# must load initial values manually instead of relying on
# Settings.changed() signal.
func _ready():
	var settings_file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)

	if settings_file != null and settings_file.get_length() > 0:
		var cache_string: String = settings_file.get_as_text()
		_cache = JSON.parse_string(cache_string) as Dictionary
		_validate_cache()
		
		print_verbose("Opened settings file at path:", settings_file.get_path_absolute())
	else:
		var open_error: Error = FileAccess.get_open_error()
		if open_error == Error.ERR_FILE_NOT_FOUND:
			print_verbose("No settings file found. Will create new one from scratch.")
		else:
			push_error("Failed to open settings file. Error:", error_string(open_error))

		_cache = _default_value_map

#		NOTE: call flush() to save default settings to file.
#		This will create settings file for the first time.
		flush()

	_load_window_settings()
	
	load_language_setting()


# NOTE: need to switch fonts when switching languages
# because the English "Friz" font doesn't support Chinese
# characters. If we don't switch, then on desktop the game
# will fallback to system font and Chinese will render ok.
# On html5, system fonts are not available and Chinese
# characters won't draw at all - that's why this step is
# necessary.
func load_language_setting():
	var selected_language: String = get_setting(Settings.LANGUAGE)
	TranslationServer.set_locale(selected_language)
	
	var chinese_locale: String = Language.get_locale_from_enum(Language.enm.CHINESE)
	var font_for_selected_language: Font
	if selected_language == chinese_locale:
		font_for_selected_language = Preloads.noto_sans_chinese_font
	else:
		font_for_selected_language = Preloads.friz_font
	
	var theme: Theme = preload("res://resources/theme/wc3_theme.tres")
	theme.default_font = font_for_selected_language


#########################
###       Public      ###
#########################

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
	
	if setting == Settings.LANGUAGE:
		load_language_setting()


# Save all changes to file
func flush():
	var settings_file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	var cache_string: String = JSON.stringify(_cache, "    ")
	settings_file.store_line(cache_string)

	_load_window_settings()
	
	changed.emit()


func get_interface_size_enum() -> Settings.InterfaceSize:
	var interface_size_int: int = Settings.get_setting(Settings.INTERFACE_SIZE) as int
	var interface_size_enum: Settings.InterfaceSize = interface_size_int as Settings.InterfaceSize
	
	return interface_size_enum


func get_interface_size() -> float:
	var interface_size_enum: Settings.InterfaceSize = get_interface_size_enum()
	var interface_size: float = INTERFACE_SIZE_DICT[interface_size_enum]

	return interface_size


# NOTE: need to convert keys to ints because JSON dicts
# forces keys to be strings.
func get_wisdom_upgrades() -> Dictionary:
	var upgrades_from_file: Dictionary = Settings.get_setting(Settings.WISDOM_UPGRADES_CACHED) as Dictionary
	
	var result: Dictionary = {}

	var upgrade_id_list: Array = WisdomUpgradeProperties.get_id_list()
	for upgrade_id in upgrade_id_list:
		if upgrades_from_file.has(upgrade_id):
			result[upgrade_id] = upgrades_from_file[upgrade_id]
		elif upgrades_from_file.has(str(upgrade_id)):
			result[upgrade_id] = upgrades_from_file[str(upgrade_id)]
		else:
			result[upgrade_id] = false

	return result


#########################
###      Private      ###
#########################

func _validate_cache():
	var cache_was_fixed: bool = false

	for _cache_key in _default_value_map.keys():
		if !_cache.has(_cache_key):
			push_error("Settings file doesn't have value for [%s]. Loading default value instead." % _cache_key)
			_cache[_cache_key] = _default_value_map[_cache_key]
			cache_was_fixed = true

#		Cache should have comparable types with the default map
		if typeof(_default_value_map[_cache_key]) != typeof(_cache[_cache_key]):
			push_error("Saved setting [%s] has incorrect type. Loading default value instead." % _cache_key)
			_cache[_cache_key] = _default_value_map[_cache_key]
			cache_was_fixed = true

#	NOTE: need to flush settings if cache was fixed to save
#	fixed settings to file
	if cache_was_fixed:
		flush()


func _load_window_settings():
	var window: Window = get_window()

	var interface_size: float = Settings.get_interface_size()
	window.content_scale_factor = interface_size

	var display_mode_int: int = Settings.get_setting(Settings.DISPLAY_MODE) as int
	var display_mode: DisplayMode.enm = display_mode_int as DisplayMode.enm
	var window_mode: Window.Mode = DisplayMode.convert_to_window_mode(display_mode)
	window.set_mode(window_mode)
