extends Control


signal tower_info_requested(tower_id)
signal tower_info_canceled
signal element_changed(element)
signal resize_icons


onready var builder_control = get_tree().current_scene.get_node(@"%BuilderControl")


func _ready():
	self.hide()
	builder_control.connect("tower_built", self, "_on_Tower_built")


func set_element(element: int):
	emit_signal("element_changed", element)
	show()


func _unhandled_input(event):
	if event.is_action_released("ui_cancel"):
		hide()


func _on_BuildBar_child_entered_tree(tower_button):
	var tower_id = tower_button.get_tower().get_id()
	tower_button.connect("mouse_entered", self, "_on_TowerButton_mouse_entered", [tower_id])
	tower_button.connect("mouse_exited", self, "_on_TowerButton_mouse_exited", [tower_id])


func _on_TowerButton_mouse_entered(tower_id):
	emit_signal("tower_info_requested", tower_id)


func _on_TowerButton_mouse_exited(_tower_id):
	emit_signal("tower_info_canceled")


func _on_Tower_built(_tower_id):
	hide()

