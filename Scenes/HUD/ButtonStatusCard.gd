class_name ButtonStatusCard
extends PanelContainer


@export var _expand_button: Button
@export var _hidable_status_panels: Array[Control]


func _on_expand_button_toggled(toggled):
	_expand_button.visible = not toggled
	for status_panel in _hidable_status_panels:
		status_panel.visible = toggled


func _unhandled_input(event):
	var cancelled: bool = event.is_action_released("ui_cancel")
	var left_click: bool = event.is_action_released("left_click")
	if cancelled or left_click:
		_expand_button.set_pressed(false)
