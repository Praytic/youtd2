# Feature Flags (FF) node contains methods for enabling/disabling
# certain functionality
extends Node


func log_debug_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/log_debug_enabled") as bool

func fast_waves_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/fast_waves") as bool

func visible_spell_dummys_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/visible_spell_dummys") as bool

func dev_controls_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/dev_controls") as bool

func add_test_item() -> bool:
	return ProjectSettings.get_setting("application/config/add_test_item") as bool

func preload_all_towers_on_startup() -> bool:
	return ProjectSettings.get_setting("application/config/preload_all_towers_on_startup") as bool
