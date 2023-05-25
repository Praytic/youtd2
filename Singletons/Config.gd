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

# Adds a list of test items to item bar. List is defined in
# ItemBar script.
func add_test_item() -> bool:
	return ProjectSettings.get_setting("application/config/add_test_item") as bool

# Load all tower scenes on startup. Otherwise tower scenes
# will be loaded when needed.
func preload_all_towers_on_startup() -> bool:
	return ProjectSettings.get_setting("application/config/preload_all_towers_on_startup") as bool

# Enable to load unreleased towers
func load_unreleased_towers() -> bool:
	return ProjectSettings.get_setting("application/config/preload_all_towers_on_startup") as bool

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

# Enables display of all tower tiers in tower build menu.
# Normally, only the first tier is displayed and further
# tiers are built by upgrading towers.
func display_all_tower_tiers() -> bool:
	return ProjectSettings.get_setting("application/config/display_all_tower_tiers") as bool

# Enable to make creeps always drop items on death.
# Normally, items drop rarely, depending on creep's and
# caster's item chance stats.
func always_drop_items() -> bool:
	return ProjectSettings.get_setting("application/config/always_drop_items") as bool
