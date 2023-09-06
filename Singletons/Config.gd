extends Node


# A collection of config items that can be defined in
# project.godot or override.cfg. Use override.cfg to locally
# override a config value without commiting the value to the
# repo.


# Set starting research level for all elements.
func starting_research_level() -> int:
	return ProjectSettings.get_setting("application/config/starting_research_level") as int

func starting_gold() -> int:
	return ProjectSettings.get_setting("application/config/starting_gold") as int

func starting_tomes() -> int:
	return ProjectSettings.get_setting("application/config/starting_tomes") as int

# Removes time delay between waves 
func fast_waves_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/fast_waves") as bool

# Displays a godot icon texture on the location of a spell dummy.
func visible_spell_dummys_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/visible_spell_dummys") as bool

func dev_controls_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/dev_controls") as bool

# A list of items which will be added to stash when game the
# starts. Leave as empty "[]" to not add any items.
func test_item_list() -> Array:
	return ProjectSettings.get_setting("application/config/test_item_list") as Array

# Load all tower scenes on startup. Otherwise tower scenes
# will be loaded when needed.
func preload_all_towers_on_startup() -> bool:
	return ProjectSettings.get_setting("application/config/preload_all_towers_on_startup") as bool

# Enable to load unreleased towers
func load_unreleased_towers() -> bool:
	return ProjectSettings.get_setting("application/config/load_unreleased_towers") as bool

func build_version() -> String:
	return ProjectSettings.get_setting("application/config/version") as String

func minimap_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/minimap_enabled") as bool

# Turns on visible damage numbers for all tower attacks.
func damage_numbers() -> bool:
	return ProjectSettings.get_setting("application/config/damage_numbers") as bool

# Disables requirements for building and upgrading towers.
# You will be able to perform all actions even if you don't
# have enough gold, tomes or research levels.
func ignore_requirements() -> bool:
	return ProjectSettings.get_setting("application/config/ignore_requirements") as bool

# Enables sound effects. Currently disabled because sfx are
# a work in progress.
func sfx_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/sfx_enabled") as bool

# Enable to make creeps always drop items on death.
# Normally, items drop rarely, depending on creep's and
# caster's item chance stats.
func always_drop_items() -> bool:
	return ProjectSettings.get_setting("application/config/always_drop_items") as bool

# Enable to be able to upgrade towers even if requirements
# are not satisfied.
func ignore_upgrade_requirements() -> bool:
	return ProjectSettings.get_setting("application/config/ignore_upgrade_requirements") as bool

# Enable to be able to zoom camera in and out using the
# touchpad.
func enable_zoom_by_touchpad() -> bool:
	return ProjectSettings.get_setting("application/config/enable_zoom_by_touchpad") as bool

# Enable to be able to zoom camera in and out using the
# mousewheel.
func enable_zoom_by_mousewheel() -> bool:
	return ProjectSettings.get_setting("application/config/enable_zoom_by_mousewheel") as bool

# Enable to show position info label under mouse. Used for
# debugging.
func show_position_info_label() -> bool:
	return ProjectSettings.get_setting("application/config/show_position_info_label") as bool

# Print errors about towers, like missing icons or scenes.
func print_errors_about_towers() -> bool:
	return ProjectSettings.get_setting("application/config/print_errors_about_towers") as bool


# Set to false to skip the pregame settings menu. In that
# case, the default values for settings will be loaded.
func show_pregame_settings_menu() -> bool:
	return ProjectSettings.get_setting("application/config/show_pregame_settings_menu") as bool


# Values for default game settings. These values will be
# loaded if show_pregame_settings_menu is set to "false".
# Note that these values will be ignored if the pregame
# settings menu is enabled.
func default_wave_count() -> int:
	return ProjectSettings.get_setting("application/config/default_wave_count") as int

func default_game_mode() -> GameMode.enm:
	var game_mode_string: String = ProjectSettings.get_setting("application/config/default_game_mode") as String
	var game_mode: GameMode.enm = GameMode.from_string(game_mode_string)

	return game_mode

func default_difficulty() -> Difficulty.enm:
	var difficulty_string: String = ProjectSettings.get_setting("application/config/default_difficulty") as String
	var difficulty: Difficulty.enm = Difficulty.from_string(difficulty_string)

	return difficulty

func default_tutorial_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/default_tutorial_enabled") as bool

# Enable to set random counters for item and tower buttons,
# for testing purposes.
func random_button_counters() -> bool:
	return ProjectSettings.get_setting("application/config/random_button_counters") as bool

# Override wave specials so that all waves have these
# specials. Can be a single special or a comma-separated
# list.
func override_wave_specials() -> Array[int]:
	var value = ProjectSettings.get_setting("application/config/override_wave_specials")
	var result: Array[int] = []
	if value is String && value != "":
		var arr_specials = value.split(",")
		for special in arr_specials:
			result.append(special.to_int())
	if value is int:
		result.append(value)
	return result

func smart_targeting() -> bool:
	return ProjectSettings.get_setting("application/config/smart_targeting") as bool

# Override health values for all creeps to a some value.
# Leave at 0 to use normal health values.
func override_creep_health() -> float:
	return ProjectSettings.get_setting("application/config/override_creep_health") as float

func override_creep_size() -> String:
	return ProjectSettings.get_setting("application/config/override_creep_size") as String

func override_creep_armor() -> String:
	return ProjectSettings.get_setting("application/config/override_creep_armor") as String

func override_creep_race() -> String:
	return ProjectSettings.get_setting("application/config/override_creep_race") as String

func print_sfx_errors() -> bool:
	return ProjectSettings.get_setting("application/config/print_sfx_errors") as bool

func unlimited_food() -> bool:
	return ProjectSettings.get_setting("application/config/unlimited_food") as bool
