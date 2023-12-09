extends Node

# Central storage for current mouse state. Used for actions
# which use the mouse and need to disable other actions
# while the action is in progress.


signal mouse_state_changed()


enum enm {
	NONE,
	BUILD_TOWER,
	MOVE_ITEM,
	SELECT_TARGET_FOR_CAST,
	SELECT_POINT_FOR_CAST,
}

var _current_state: MouseState.enm = MouseState.enm.NONE


func set_state(state: MouseState.enm):
	_current_state = state
	mouse_state_changed.emit()


func get_state() -> MouseState.enm:
	return _current_state
