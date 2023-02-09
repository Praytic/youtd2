extends GridContainer


onready var builder_control = get_tree().current_scene.get_node(@"%BuilderControl")


func _ready():
	builder_control.connect("tower_built", self, "_on_Tower_built")


func _on_RightMenuBar_element_changed(element):
	var tower_id_list = Properties.get_csv_properties_by_filter(Tower.Property.ELEMENT, element)

	for n in get_children():
		n.queue_free()
	
	for tower_id in tower_id_list:
		_add_TowerButton(tower_id[Tower.Property.ID])


func _add_TowerButton(tower_id):
	var tower_family_id = TowerManager.get_tower_family_id(tower_id)
	var tower_button_texture = load("res://Assets/Towers/Icons/icon_min_%s.png" % tower_family_id)
	var tower_button = TowerButton.new()
	tower_button.tower_id = tower_id
	tower_button.set_theme_type_variation("TowerButton")
	tower_button.set_button_icon(tower_button_texture)
	tower_button.connect("mouse_entered", self, "_on_TowerButton_mouse_entered", [tower_id])
	tower_button.connect("mouse_exited", self, "_on_TowerButton_mouse_exited", [tower_id])
	tower_button.connect("pressed", builder_control, "on_build_button_pressed", [tower_id])
	add_child(tower_button)


func _on_TowerButton_mouse_entered(tower_id):
	emit_signal("tower_info_requested", tower_id)


func _on_TowerButton_mouse_exited():
	emit_signal("tower_info_canceled")


func _on_Tower_built(tower_id):
	for tower_button in get_children():
		if tower_button.tower_id == tower_id:
			tower_button.queue_free()
