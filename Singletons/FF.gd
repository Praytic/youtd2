# Feature Flags (FF) node contains methods for enabling/disabling
# certain functionality
extends Node


static func log_debug_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/log_debug_enabled") as bool

static func fast_waves_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/fast_waves") as bool

static func visible_spell_dummys_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/visible_spell_dummys") as bool

static func dev_controls_enabled() -> bool:
	return ProjectSettings.get_setting("application/config/dev_controls") as bool

static func add_test_item() -> bool:
	return ProjectSettings.get_setting("application/config/add_test_item") as bool
