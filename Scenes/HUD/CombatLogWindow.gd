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


@export var _label: RichTextLabel
@export var _up_button: Button
@export var _down_button: Button

var _auto_scroll_enabled: bool = true


func _ready():
	Settings.changed.connect(_on_settings_changed)
	_on_settings_changed()
	
	var saved_pos_x: float = Settings.get_setting(Settings.COMBAT_LOG_X) as float
	var saved_pos_y: float = Settings.get_setting(Settings.COMBAT_LOG_Y) as float
	global_position = Vector2(saved_pos_x, saved_pos_y)


# Disable auto scroll when player scrolls using mouse wheel
# or mouse gesture
func _unhandled_input(event: InputEvent):
	var scroll_input: bool

	if event is InputEventMagnifyGesture:
		scroll_input = true
	elif event is InputEventMouseButton:
		var input_button: MouseButton = event.get_button_index()
		var used_mouse_button_wheel: bool = input_button == MOUSE_BUTTON_WHEEL_DOWN || input_button == MOUSE_BUTTON_WHEEL_UP

		if used_mouse_button_wheel:
			scroll_input = true
		else:
			scroll_input = false
	else:
		scroll_input = false

	if scroll_input:
		_auto_scroll_enabled = false


func _process(_delta: float):
	if !visible:
		return

#	Update text
	var text: String = ""
	
	for i in range(CombatLog.size() - 1, 0, -1):
		var entry_string: String = CombatLog.get_entry_string(i)
		text += entry_string
		text += "\n"
	
	_label.clear()
	_label.append_text(text)

#	Update scrolling
	var up_is_pressed: bool = _up_button.is_pressed()
	var down_is_pressed: bool = _down_button.is_pressed()

	if up_is_pressed || down_is_pressed:
		_auto_scroll_enabled = false

	var v_scroll_bar: VScrollBar = _label.get_v_scroll_bar()
	var scroll_max: float = v_scroll_bar.max_value
	var entry_count: int = CombatLog.size()
	var scroll_per_entry: float = scroll_max / entry_count
	var current_scroll: float = v_scroll_bar.get_value()

	if up_is_pressed:
		var new_scroll: float = clampf(current_scroll - scroll_per_entry, 0, scroll_max)
		v_scroll_bar.set_value(new_scroll)
	elif down_is_pressed:
		var new_scroll: float = clampf(current_scroll + scroll_per_entry, 0, scroll_max)
		v_scroll_bar.set_value(new_scroll)
	elif _auto_scroll_enabled:
		v_scroll_bar.set_value(scroll_max)


func _on_settings_changed():
	var show_combat_log: bool = Settings.get_bool_setting(Settings.SHOW_COMBAT_LOG)
	visible = show_combat_log


func _on_auto_down_button_pressed():
	_auto_scroll_enabled = true


func _on_clear_button_pressed():
	CombatLog.clear()


func _on_drag_finished():
	Settings.set_setting(Settings.COMBAT_LOG_X, global_position.x)
	Settings.set_setting(Settings.COMBAT_LOG_Y, global_position.y)
	Settings.flush()
