extends GridContainer


onready var builder_control = get_tree().current_scene.get_node(@"%BuilderControl")


func _on_TowerOptionButton_tower_selected(selected_tower_id):
	if _has_tower_button(selected_tower_id):
		return
	
	var tower_family_id = TowerManager.get_tower_family_id(selected_tower_id)
	var tower_button_texture = load("res://Assets/Towers/Icons/icon_min_%s.png" % tower_family_id)
	var tower_button = TowerButton.new()
	tower_button.tower_id = selected_tower_id
	tower_button.set_theme_type_variation("TowerButton")
	tower_button.set_button_icon(tower_button_texture)
	tower_button.connect("mouse_entered", self, "_on_TowerButton_mouse_entered", [selected_tower_id])
	tower_button.connect("mouse_exited", self, "_on_TowerButton_mouse_exited", [selected_tower_id])
	tower_button.connect("pressed", builder_control, "on_build_button_pressed", [selected_tower_id])
	add_child(tower_button)


func _has_tower_button(tower_id) -> bool:
	for tower_button in get_children():
		if tower_button.tower_id == tower_id:
			return true
	return false
