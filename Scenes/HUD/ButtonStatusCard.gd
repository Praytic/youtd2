class_name ButtonStatusCard
extends PanelContainer


@export var _main_button: Button
@export var _expand_button: Button

@onready var _hidable_status_panels: Array = get_tree().get_nodes_in_group("hidable_status_panel")


func _ready():
	_expand_button.toggled.connect(_on_main_button_toggled)


func _on_main_button_toggled(toggled):
	for status_panel in _hidable_status_panels:
		status_panel.visible = toggled


func _unhandled_input(event):
	var cancelled: bool = event.is_action_released("ui_cancel")
	var left_click: bool = event.is_action_released("left_click")
	if cancelled or left_click:
		_expand_button.toggled.emit(false)