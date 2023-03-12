extends GridContainer


@export var unlimited_towers = false

@onready var builder_control = get_tree().current_scene.get_node("%BuilderControl")
# Dictionary of all in-game towers with the associated buttons
@onready var _tower_buttons: Dictionary = {}
# Adds every tower button possible to the list.
# Although, this is a mutable list, so every time
# you build a tower, the ID of the tower is removed from this list.
# If you want unlimited tower buttons in the panel, switch the flag
# 'unlimited towers' to 'true'.
@onready var available_tower_buttons: Array


var current_element: int
var current_size: String


func add_tower_button(tower_id):
	available_tower_buttons.append(tower_id)
	var element: int = Properties.get_csv_properties(tower_id)[Tower.CsvProperty.ELEMENT]
	if element == current_element:
		_tower_buttons[tower_id].show()


func remove_tower_button(tower_id):
	available_tower_buttons.erase(tower_id)
	_tower_buttons[tower_id].hide()


func _ready():
	if not unlimited_towers:
		builder_control.tower_built.connect(_on_Tower_built)
		
	for tower_id in Properties.get_tower_id_list():
		var tower_button = _create_TowerButton(tower_id)
		if tower_button:
			_tower_buttons[tower_id] = tower_button
			tower_button.hide()
			add_child(tower_button)
	
	for tower_id in _tower_buttons.keys():
		available_tower_buttons.append(tower_id)
	
	_resize_icons("M")
	current_size = "M"

func _on_RightMenuBar_element_changed(element: int):
	current_element = element
	
	for tower_button in _tower_buttons.values():
		tower_button.hide()
	
	if current_element == -1:
		# Items menu bar was selected
		return
	
	var available_towers_for_element = _get_available_tower_buttons_for_element(element)
	if current_size == "M":
		if available_towers_for_element.size() > 14:
			_resize_icons("S")
		else:
			_resize_icons("M")
	elif current_size == "S":
		if available_towers_for_element.size() > 14:
			_resize_icons("S")
		else:
			_resize_icons("M")
	
	for tower_id in available_towers_for_element:
		_tower_buttons[tower_id].show()

func _create_TowerButton(tower_id) -> TowerButton:
	var tower_button = TowerButton.new()
	tower_button.set_tower(TowerManager.get_tower(tower_id))
	tower_button.pressed.connect(Callable(builder_control, "on_build_button_pressed").bind(tower_id))
	return tower_button


func _on_Tower_built(tower_id):
	remove_tower_button(tower_id)


func _resize_icons(icon_size: String):
	current_size = icon_size
	if icon_size == "M":
		columns = 2
	else:
		columns = 4
	for tower_id in _get_available_tower_buttons_for_element(current_element):
		_tower_buttons[tower_id].set_icon_size(icon_size)


func _get_available_tower_buttons_for_element(element: int) -> Array:
	var element_string: String = Tower.Element.keys()[element].to_lower()
	var tower_id_list = Properties.get_tower_id_list_by_filter(Tower.CsvProperty.ELEMENT, element_string)
	
	var res: Array = []
	for tower_id in tower_id_list:
		if available_tower_buttons.has(tower_id):
			res.append(tower_id)
	
	return res
