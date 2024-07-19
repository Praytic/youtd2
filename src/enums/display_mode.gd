class_name DisplayMode extends Node

# NOTE: there is already a Window.Mode enum but it contains
# all possible values in a specific order. This enum is
# needed to represent indexes in the "Display mode" setting
# in settings menu. For settings, we need only some of the
# values and in a different order than Window.Mode.

enum enm {
	FULLSCREEN,
	BORDERLESS,
	WINDOWED,
}

static var _window_mode_map: Dictionary = {
	DisplayMode.enm.FULLSCREEN: Window.Mode.MODE_EXCLUSIVE_FULLSCREEN,
	DisplayMode.enm.BORDERLESS: Window.Mode.MODE_FULLSCREEN,
	DisplayMode.enm.WINDOWED: Window.Mode.MODE_WINDOWED,
}


static func convert_to_window_mode(type: DisplayMode.enm) -> Window.Mode:
	return _window_mode_map[type]
