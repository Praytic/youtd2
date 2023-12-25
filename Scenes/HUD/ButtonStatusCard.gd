class_name ButtonStatusCard
extends PanelContainer


enum VisibilityLevel {
	FULL = 0,
	ESSENTIALS = 1,
	MENU_OPENED = 2,
	MENU_CLOSED = 3,
}


@export var _expand_button: Button
@export var _hidable_status_panels: Array[Control]
@export var _status_panels: Array[Control]
@export var _panels_container: Control


func _on_expand_button_pressed():
	change_visibility_level(VisibilityLevel.FULL)


func _unhandled_input(event):
	var cancelled: bool = event.is_action_released("ui_cancel")
	var left_click: bool = event.is_action_released("left_click")
	if cancelled or left_click:
		change_visibility_level(VisibilityLevel.ESSENTIALS)


func change_visibility_level(visibility_level: VisibilityLevel):
	match visibility_level:
		VisibilityLevel.FULL: 
			for status_panel in _status_panels:
				status_panel.visible = true
			_expand_button.visible = false 
			_panels_container.visible = true
		VisibilityLevel.ESSENTIALS: 
			for status_panel in _status_panels:
				status_panel.visible = true
			for status_panel in _hidable_status_panels:
				status_panel.visible = false
			_expand_button.visible = true 
			_panels_container.visible = true
		VisibilityLevel.MENU_OPENED: 
			for status_panel in _status_panels:
				status_panel.visible = false
			_expand_button.visible = false
			_panels_container.visible = true
		VisibilityLevel.MENU_CLOSED:
			_panels_container.visible = false
