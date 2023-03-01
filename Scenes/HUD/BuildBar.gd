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
onready var _tower_buttons_texture = preload("res://Assets/Towers/tower_icons.png")
onready var _tower_button_fallback_icon = preload("res://Assets/icon.png")
onready var _tower_buttons_atlas_texture: AtlasTexture


var current_element: int


func add_tower_button(tower_id):
	available_tower_buttons.append(tower_id)
	var element: int = Properties.get_csv_properties(tower_id)[Tower.CsvProperty.ELEMENT]
	if element == current_element:
		_tower_buttons[tower_id].show()


func remove_tower_button(tower_id):
	available_tower_buttons.erase(tower_id)
	_tower_buttons[tower_id].hide()


func _ready():
	_tower_buttons_atlas_texture = AtlasTexture.new()
	_tower_buttons_atlas_texture.set_atlas(_tower_buttons_texture)
	
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


func _on_RightMenuBar_element_changed(element: int):
	current_element = element
	var element_string: String = Tower.Element.keys()[element].to_lower()
	var tower_id_list = Properties.get_tower_id_list_by_filter(Tower.CsvProperty.ELEMENT, element_string)
	
	for tower_button in _tower_buttons.values():
		tower_button.hide()
	
	for tower_id in tower_id_list:
		if available_tower_buttons.has(tower_id):
			_tower_buttons[tower_id].show()


func _create_TowerButton(tower_id) -> TowerButton:
	var tower_button = TowerButton.new()
	var button_icon: Texture = _get_tower_button_icon(tower_id)
	tower_button.set_button_icon(button_icon)
	tower_button.tower_id = tower_id
	tower_button.set_theme_type_variation("TowerButton")
	tower_button.connect("pressed", builder_control, "on_build_button_pressed", [tower_id])
	return tower_button


func _get_tower_button_icon(tower_id: int) -> Texture:
	var tower = TowerManager.get_tower(tower_id)
	var icon_atlas_num: int = tower.get_icon_atlas_num()
	var icon_is_defined: bool = icon_atlas_num != -1

	if icon_is_defined:
		var region: Rect2 = Rect2(tower.get_element() * 64, icon_atlas_num * 64, 64, 64)
		var atlas: AtlasTexture = _tower_buttons_atlas_texture.duplicate()
		atlas.set_region(region)

		return atlas
	else:
		return _tower_button_fallback_icon


func _on_TowerButton_mouse_entered(tower_id):
	emit_signal("tower_info_requested", tower_id)


func _on_TowerButton_mouse_exited(_tower_id):
	emit_signal("tower_info_canceled")


func _on_Tower_built(tower_id):
	remove_tower_button(tower_id)
