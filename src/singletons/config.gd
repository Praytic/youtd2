extends Node


# A collection of config items that can be defined in
# project.godot or override.cfg. Use override.cfg to locally
# override a config value without commiting the value to the
# repo.


func cheat_gold() -> int:
	return ProjectSettings.get_setting("application/config/cheat_gold") as int

func cheat_tomes() -> int:
	return ProjectSettings.get_setting("application/config/cheat_tomes") as int

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

func build_version() -> String:
	return ProjectSettings.get_setting("application/config/version") as String

# Enable to make creeps always drop items on death.
# Normally, items drop rarely, depending on creep's and
# caster's item chance stats.
func always_drop_items() -> bool:
	return ProjectSettings.get_setting("application/config/always_drop_items") as bool

# Makes the game ignore required wave level and element
# level.
func ignore_tower_requirements() -> bool:
	return ProjectSettings.get_setting("application/config/ignore_tower_requirements") as bool

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

# Override wave specials so that all waves have these
# specials. Can be a single special or a comma-separated
# list.
func override_wave_specials() -> Array[int]:
	var array: Array = ProjectSettings.get_setting("application/config/override_wave_specials") as Array

	var result: Array[int] = []
	for value in array:
		result.append(value as int)

	return result

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

func cheat_food_cap() -> int:
	return ProjectSettings.get_setting("application/config/cheat_food_cap") as int

func allow_transform_in_build_mode() -> bool:
	return ProjectSettings.get_setting("application/config/allow_transform_in_build_mode") as bool

func load_only_orc_scenes() -> bool:
	return ProjectSettings.get_setting("application/config/load_only_orc_scenes") as bool

func run_test_towers_tool() -> bool:
	return ProjectSettings.get_setting("application/config/run_test_towers_tool") as bool

func run_auto_playtest_bot() -> bool:
	return ProjectSettings.get_setting("application/config/run_auto_playtest_bot") as bool

func run_test_items_tool() -> bool:
	return ProjectSettings.get_setting("application/config/run_test_items_tool") as bool

func run_test_horadric_tool() -> bool:
	return ProjectSettings.get_setting("application/config/run_test_horadric_tool") as bool

func run_test_tower_sprite_size() -> bool:
	return ProjectSettings.get_setting("application/config/run_test_tower_sprite_size") as bool

func run_test_item_drop_chances() -> bool:
	return ProjectSettings.get_setting("application/config/run_test_item_drop_chances") as bool

func unlimited_portal_lives() -> bool:
	return ProjectSettings.get_setting("application/config/unlimited_portal_lives") as bool

func show_hidden_buffs() -> bool:
	return ProjectSettings.get_setting("application/config/show_hidden_buffs") as bool

# NOTE: increasing this valid makes the game run at super
# speed
func update_ticks_per_physics_tick() -> int:
	return ProjectSettings.get_setting("application/config/update_ticks_per_physics_tick") as int

func enable_dev_commands() -> bool:
	return ProjectSettings.get_setting("application/config/enable_dev_commands") as bool

func print_wave_info() -> bool:
	return ProjectSettings.get_setting("application/config/print_wave_info") as bool
