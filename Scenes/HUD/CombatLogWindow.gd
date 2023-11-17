extends MovableWindow


# Displays log entries collected by CombatLog. Can be
# shown/hidden via settings.

# NOTE: using custom MovableWindow instead of the built-in
# Godot class "Window" because Window steals all input focus
# when you interact with it. You need to constantly click
# outside of the Window to be able to give inputs to the
# rest of the game, which is annoying. The custom
# MovableWindow is missing some functionality but it works
# nicely with the rest of the game in terms of input.


# NOTE: 22 lines is the amount of lines which fit within
# combat log window without causing the scrollbar to appear.
const DISPLAYED_LINE_COUNT: int = 22

@export var _label: RichTextLabel
@export var _up_button: Button
@export var _down_button: Button

var _auto_scroll_to_newest: bool = true
var _displayed_max_index: int = 0


func _ready():
	Settings.changed.connect(_on_settings_changed)
	_on_settings_changed()
	
	var saved_pos_x: float = Settings.get_setting(Settings.COMBAT_LOG_X) as float
	var saved_pos_y: float = Settings.get_setting(Settings.COMBAT_LOG_Y) as float
	global_position = Vector2(saved_pos_x, saved_pos_y)


func _process(_delta: float):
	if !visible:
		return

	var text: String = ""

	var displayed_min_index: int = _displayed_max_index - DISPLAYED_LINE_COUNT
	
	for i in range(displayed_min_index, _displayed_max_index):
		var entry_string: String = CombatLog.get_entry_string(i)

		if !entry_string.is_empty():
			text += entry_string
			text += "\n"
		else:
#			Pad lines which are out of bounds
			text += " \n"

	_label.clear()
	_label.append_text(text)

#	Update scrolling
	var up_is_pressed: bool = _up_button.is_pressed()
	var down_is_pressed: bool = _down_button.is_pressed()

	if up_is_pressed || down_is_pressed:
		_auto_scroll_to_newest = false

	if up_is_pressed:
#		Add +1 so that at least one line is displayed at any
#		time
		_displayed_max_index = max(CombatLog.get_min_index() + 1, _displayed_max_index - 1)
	elif down_is_pressed:
		_displayed_max_index = min(CombatLog.get_max_index(), _displayed_max_index + 1)

		var scrolled_to_bottom: bool = _displayed_max_index == CombatLog.get_max_index()
		if scrolled_to_bottom:
			_auto_scroll_to_newest = true
	elif _auto_scroll_to_newest:
		_displayed_max_index = CombatLog.get_max_index()

#	Current display position can go out of bounds while
#	CombatLog erases messages which are too old. Move the
#	index up in this case.
	if _displayed_max_index < CombatLog.get_min_index():
		_displayed_max_index = CombatLog.get_min_index() + 1


func _on_settings_changed():
	var show_combat_log: bool = Settings.get_bool_setting(Settings.SHOW_COMBAT_LOG)
	visible = show_combat_log


func _on_auto_down_button_pressed():
	_auto_scroll_to_newest = true


func _on_clear_button_pressed():
	CombatLog.clear()


func _on_drag_finished():
	Settings.set_setting(Settings.COMBAT_LOG_X, global_position.x)
	Settings.set_setting(Settings.COMBAT_LOG_Y, global_position.y)
	Settings.flush()
