extends Control


signal tower_info_requested(tower_id)
signal tower_info_canceled


onready var builder_control = get_tree().current_scene.get_node(@"%BuilderControl")
onready var tower_option_button: OptionButton = $VBoxContainer/TowerOptionButton


func _ready():
	self.hide()


func _on_Button_pressed():
	show()


func _unhandled_input(event):
	if event.is_action_released("ui_cancel"):
		hide()


func _on_BuildSelectedTowerButton_pressed():
	var selected_tower_id: int = tower_option_button.get_selected_id()
	builder_control.on_build_button_pressed(selected_tower_id)
	hide()


func _on_BuildBar_child_entered_tree(tower_button):
	var tower_id = tower_button.tower_id
	tower_button.connect("mouse_entered", self, "_on_TowerButton_mouse_entered", [tower_id])
	tower_button.connect("mouse_exited", self, "_on_TowerButton_mouse_exited")
	
func _on_TowerButton_mouse_entered(tower_id):
	emit_signal("tower_info_requested", tower_id)
	
	
func _on_TowerButton_mouse_exited():
	emit_signal("tower_info_canceled")
