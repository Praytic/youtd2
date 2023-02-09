extends GridContainer


export (bool) var unlimited_towers = false

onready var builder_control = get_tree().current_scene.get_node(@"%BuilderControl")
# Dictionary of all in-game towers with the associated buttons
onready var _tower_buttons: Dictionary = {}
# Adds every tower button possible to the list.
# Although, this is a mutable list, so every time
# you build a tower, the ID of the tower is removed from this list.
# If you want unlimited tower buttons in the panel, switch the flag
# 'unlimited towers' to 'true'.
onready var available_tower_buttons: Array


var current_element: String


func add_tower_button(tower_id):
	available_tower_buttons.append(tower_id)
	var element = Properties.get_csv_properties(tower_id)[Tower.Property.ELEMENT]
	if element == current_element:
		_tower_buttons[tower_id].show()


func remove_tower_button(tower_id):
	available_tower_buttons.erase(tower_id)
	_tower_buttons[tower_id].hide()


func _ready():
	if not unlimited_towers:
		builder_control.connect("tower_built", self, "_on_Tower_built")
		
	for tower_id in Properties.get_tower_id_list():
		var tower_button = _create_TowerButton(tower_id)
		if tower_button:
			_tower_buttons[tower_id] = tower_button
			tower_button.hide()
			add_child(tower_button)
	
	for tower_id in _tower_buttons.keys():
		available_tower_buttons.append(tower_id)


func _on_RightMenuBar_element_changed(element):
	current_element = element
	var tower_id_list = Properties.get_tower_id_list_by_filter(Tower.Property.ELEMENT, element)
	
	for tower_button in _tower_buttons.values():
		tower_button.hide()
	
	for tower_id in tower_id_list:
		if available_tower_buttons.has(tower_id):
			_tower_buttons[tower_id].show()


func _create_TowerButton(tower_id) -> TowerButton:
	var tower_family_id = TowerManager.get_tower_family_id(tower_id)
	var tower_button_texture = load("res://Assets/Towers/Icons/icon_min_%s.png" % tower_family_id)
	if tower_button_texture == null:
		return null
	
	var tower_button = TowerButton.new()
	tower_button.tower_id = tower_id
	tower_button.set_theme_type_variation("TowerButton")
	tower_button.set_button_icon(tower_button_texture)
	tower_button.connect("pressed", builder_control, "on_build_button_pressed", [tower_id])
	return tower_button


func _on_TowerButton_mouse_entered(tower_id):
	emit_signal("tower_info_requested", tower_id)


func _on_TowerButton_mouse_exited(_tower_id):
	emit_signal("tower_info_canceled")


func _on_Tower_built(tower_id):
	remove_tower_button(tower_id)
