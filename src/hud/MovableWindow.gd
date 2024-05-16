class_name MovableWindow extends VBoxContainer


# Window which can be moved by dragging the title label.
# It's a partial reimplementation of Godot's built-in Window
# class but without having using a separate Viewport which
# avoids some problems like splitting input focus.


signal drag_finished()


enum State {
	IDLE,
	DRAGGING,
}

@export var _title_panel: PanelContainer

var _drag_state: State = State.IDLE
var _drag_offset: Vector2 = Vector2.ZERO


func _input(event: InputEvent):
	if !event is InputEventMouse:
		return

	var viewport_scale: Vector2 = get_viewport_transform().get_scale()
	var input_pos: Vector2 = event.global_position / viewport_scale
	var title_pos: Vector2 = _title_panel.global_position
	var title_size: Vector2 = _title_panel.get_size()
	var title_rect: Rect2 = Rect2(title_pos, title_size)
	var clicked_on_title_label: bool = event.is_action_pressed("left_click") && title_rect.has_point(input_pos)
	
	if event.is_action_released("left_click"):
		_drag_state = State.IDLE

		return

	if clicked_on_title_label:
		_drag_state = State.DRAGGING
		_drag_offset = global_position - input_pos
	
	var drag_is_in_progress: bool = event is InputEventMouseMotion && _drag_state == State.DRAGGING
	
	if drag_is_in_progress:
		global_position = input_pos + _drag_offset
		drag_finished.emit()
