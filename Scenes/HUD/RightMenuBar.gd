extends Control


signal tower_info_requested(tower_id)
signal tower_info_canceled
signal item_info_requested(item_id)
signal item_info_canceled
signal element_changed(element)


@onready var builder_control = get_tree().current_scene.get_node("%BuilderControl")
@onready var item_control = get_tree().current_scene.get_node("%ItemControl")


func _ready():
	self.hide()
	builder_control.connect("tower_built",Callable(self,"_on_Tower_built"))
	item_control.connect("item_used",Callable(self,"_on_Item_used"))


func set_element(element: int):
	emit_signal("element_changed", element)
	show()


func _unhandled_input(event):
	if event.is_action_released("ui_cancel"):
		hide()


func _on_BuildBar_child_entered_tree(unit_button):
	if unit_button is TowerButton:
		var tower_id = unit_button.get_tower().get_id()
		unit_button.connect("mouse_entered",Callable(self,"_on_TowerButton_mouse_entered").bind(tower_id))
		unit_button.connect("mouse_exited",Callable(self,"_on_TowerButton_mouse_exited").bind(tower_id))
	if unit_button is ItemButton:
		var item_id = unit_button.get_item().get_id()
		unit_button.connect("mouse_entered",Callable(self,"_on_ItemButton_mouse_entered").bind(item_id))
		unit_button.connect("mouse_exited",Callable(self,"_on_ItemButton_mouse_exited").bind(item_id))


func _on_TowerButton_mouse_entered(tower_id):
	emit_signal("tower_info_requested", tower_id)


func _on_TowerButton_mouse_exited(_tower_id):
	emit_signal("tower_info_canceled")


func _on_ItemButton_mouse_entered(item_id):
	emit_signal("item_info_requested", item_id)


func _on_ItemButton_mouse_exited(_item_id):
	emit_signal("item_info_canceled")


func _on_Tower_built(_tower_id):
	hide()


func _on_Item_used(_item_id):
	hide()
