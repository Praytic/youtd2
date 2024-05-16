class_name SelectTargetForCast extends Node

# Implements selection of target when player is casting a
# tower ability manually.

var _autocast: Autocast = null

const _cast_cursor: Texture2D = preload("res://assets/Misc/cast_cursor.png")

@export var _mouse_state: MouseState
@export var _game_client: GameClient


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

	if !target_is_ok:
		Messages.add_error(PlayerManager.get_local_player(), target_error_message)

		return
		
	var can_cast: bool = _autocast.can_cast()

	if !can_cast:
		_autocast.add_cast_error_message()

		return

	var autocast_uid: int = _autocast.get_uid()
	var target_uid: int = target.get_uid()
	var target_pos: Vector2 = Vector2.ZERO
	var action: Action = ActionAutocast.make(autocast_uid, target_uid, target_pos)
	_game_client.add_action(action)

	cancel()


func start(autocast: Autocast):
	var can_start: bool = _mouse_state.get_state() == MouseState.enm.NONE || _mouse_state.get_state() == MouseState.enm.SELECT_TARGET_FOR_CAST
	if !can_start:
		return

	cancel()
	_autocast = autocast
	_mouse_state.set_state(MouseState.enm.SELECT_TARGET_FOR_CAST)
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
	return _mouse_state.get_state() == MouseState.enm.SELECT_TARGET_FOR_CAST
