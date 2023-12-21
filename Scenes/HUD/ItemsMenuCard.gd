class_name ButtonStatusCard
extends PanelContainer


@export var _main_button: Button

@onready var _hidable_status_panels: Array = get_tree().get_nodes_in_group("hidable_status_panel")


func _ready():
	_main_button.toggled.connect(_on_main_button_toggled)


func _on_main_button_toggled(toggled):
	for status_panel in _hidable_status_panels:
		status_panel.visible = toggled
