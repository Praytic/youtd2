extends Control


onready var builder_control = get_tree().current_scene.get_node(@"%BuilderControl")
onready var tower_option_button: OptionButton = $VBoxContainer/TowerOptionButton


func _ready():
	self.hide()


func _on_Button_pressed():
	show()


func _unhandled_input(event):
	if event.is_action_released("ui_cancel") or event.is_action_released("ui_accept"):
		hide()


func _on_BuildSelectedTowerButton_pressed():
	var selected_tower_id: int = tower_option_button.get_selected_id()
	builder_control.on_build_button_pressed(selected_tower_id)
