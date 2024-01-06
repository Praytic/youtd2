extends Node

# Implements selection of point when player is casting a
# tower ability manually, and autocast is POINT type

var _autocast: Autocast = null

var _cast_cursor: Texture2D = preload("res://Assets/UI/HUD/cast_cursor.png")

@onready var _map = get_tree().get_root().get_node("GameScene").get_node("%Map")


#########################
###     Built-in      ###
#########################

func _unhandled_input(event: InputEvent):
	if !_in_progress():
		return

	var cancelled: bool = event.is_action_released("ui_cancel")

	if cancelled:
		cancel()

	var left_click: bool = event.is_action_released("left_click")

	if left_click:
		var target_pos: Vector2 = _map.get_local_mouse_position()
		var cast_success: bool = _autocast.do_cast_manually_finish_for_point(target_pos)

		if cast_success:
			cancel()

#		NOTE: need this so that the left click doesn't also
#		select the target unit
		get_viewport().set_input_as_handled()


#########################
###       Public      ###
#########################

func start(autocast: Autocast):
	var can_start: bool = MouseState.get_state() == MouseState.enm.NONE || MouseState.get_state() == MouseState.enm.SELECT_POINT_FOR_CAST
	if !can_start:
		return false

	cancel()
	_autocast = autocast
	MouseState.set_state(MouseState.enm.SELECT_POINT_FOR_CAST)
	var hotspot: Vector2 = _cast_cursor.get_size() / 2
	Input.set_custom_mouse_cursor(_cast_cursor, Input.CURSOR_ARROW, hotspot)


func cancel():
	if !_in_progress():
		return

	MouseState.set_state(MouseState.enm.NONE)

	_autocast = null

#	NOTE: for some reason need to call this twice to reset
#	the cursor. Calling it once causes the cursor to
#	disappear.
	Input.set_custom_mouse_cursor(null)
	Input.set_custom_mouse_cursor(null)


#########################
###      Private      ###
#########################

func _in_progress() -> bool:
	return MouseState.get_state() == MouseState.enm.SELECT_POINT_FOR_CAST
