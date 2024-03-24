class_name SelectPointForCast extends Node

# Implements selection of point when player is casting a
# tower ability manually, and autocast is POINT type

var _autocast: Autocast = null

const _cast_cursor: Texture2D = preload("res://Assets/UI/HUD/cast_cursor.png")

@export var _mouse_state: MouseState


#########################
###       Public      ###
#########################

func finish(map: Map):
	if !_in_progress():
		return

	var target_pos: Vector2 = map.get_local_mouse_position()

	var can_cast: bool = _autocast.can_cast()
	if !can_cast:
		_autocast.add_cast_error_message()

		return

	var in_range: bool = _autocast.target_pos_is_in_range(target_pos)
	if !in_range:
		Messages.add_error(Globals.get_local_player(), "Out of range")

		return

	_autocast.do_cast_at_pos(target_pos)
	cancel()


func start(autocast: Autocast):
	var can_start: bool = _mouse_state.get_state() == MouseState.enm.NONE || _mouse_state.get_state() == MouseState.enm.SELECT_POINT_FOR_CAST
	if !can_start:
		return

	cancel()
	_autocast = autocast
	_mouse_state.set_state(MouseState.enm.SELECT_POINT_FOR_CAST)
	var hotspot: Vector2 = _cast_cursor.get_size() / 2
	Input.set_custom_mouse_cursor(_cast_cursor, Input.CURSOR_ARROW, hotspot)


func cancel():
	if !_in_progress():
		return

	_mouse_state.set_state(MouseState.enm.NONE)

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
	return _mouse_state.get_state() == MouseState.enm.SELECT_POINT_FOR_CAST
