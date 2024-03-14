class_name SelectTargetForCast extends Node

# Implements selection of target when player is casting a
# tower ability manually.

var _autocast: Autocast = null

const _cast_cursor: Texture2D = preload("res://Assets/UI/HUD/cast_cursor.png")


#########################
###       Public      ###
#########################

func finish(hovered_unit: Unit):
	if !_in_progress():
		return

	var target: Unit = hovered_unit

	if target == null:
		return

	var target_is_ok: bool = _autocast.check_target_for_unit_autocast(target)
	var target_error_message: String = _autocast.get_target_error_message(target)

	if target_is_ok:
		var cast_success: bool = _autocast.do_cast_manually_finish_for_manual_target(target)

		if cast_success:
			cancel()

#		NOTE: need this so that the left click doesn't
#		also select the target unit
		get_viewport().set_input_as_handled()
	else:
		Messages.add_error(target_error_message)


func start(autocast: Autocast):
	var can_start: bool = MouseState.get_state() == MouseState.enm.NONE || MouseState.get_state() == MouseState.enm.SELECT_TARGET_FOR_CAST
	if !can_start:
		return

	cancel()
	_autocast = autocast
	MouseState.set_state(MouseState.enm.SELECT_TARGET_FOR_CAST)
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
	return MouseState.get_state() == MouseState.enm.SELECT_TARGET_FOR_CAST
