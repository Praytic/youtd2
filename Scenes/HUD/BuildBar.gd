extends GridContainer


@export var unlimited_towers = false

# Dictionary of all in-game towers with the associated buttons
@onready var _tower_buttons: Dictionary = {}
# Adds every tower button possible to the list.
# Although, this is a mutable list, so every time
# you build a tower, the ID of the tower is removed from this list.
# If you want unlimited tower buttons in the panel, switch the flag
# 'unlimited towers' to 'true'.
@onready var available_tower_buttons: Array


var current_element: Element.enm
var current_size: String


func add_tower_button(tower_id):
	available_tower_buttons.append(tower_id)
	var element: Element.enm = Properties.get_csv_properties(tower_id)[Tower.CsvProperty.ELEMENT]
	if element == current_element:
		_tower_buttons[tower_id].show()


func remove_tower_button(tower_id):
	available_tower_buttons.erase(tower_id)
	_tower_buttons[tower_id].hide()


func _ready():
	print_verbose("Start loading BuildBar.")
	
	if not unlimited_towers:
		BuildTower.tower_built.connect(_on_Tower_built)
		
	for tower_id in Properties.get_tower_id_list():
		var tower_button = _create_TowerButton(tower_id)
		if tower_button:
			_tower_buttons[tower_id] = tower_button
			tower_button.hide()
			add_child(tower_button)
	
	for tower_id in _tower_buttons.keys():
		available_tower_buttons.append(tower_id)
	
	_resize_icons("S")
	current_size = "S"
	
	print_verbose("BuildBar has loaded.")

func set_element(element: Element.enm):
	current_element = element
	
	if current_element == Element.enm.NONE:
		# Items menu bar was selected
		return
		
	for tower_button in _tower_buttons.values():
		tower_button.hide()
	
	var available_towers_for_element = _get_available_tower_buttons_for_element(element)
# Disable resize for icons in the RightMenuBar
#	if current_size == "M":
#		if available_towers_for_element.size() > 14:
#			_resize_icons("S")
#		else:
#			_resize_icons("M")
#	elif current_size == "S":
#		if available_towers_for_element.size() > 14:
#			_resize_icons("S")
#		else:
#			_resize_icons("M")
	_resize_icons("S")
	
	for tower_id in available_towers_for_element:
		_tower_buttons[tower_id].show()

func _create_TowerButton(tower_id: int) -> TowerButton:
	var tower_button = TowerButton.new()
	tower_button.set_tower(tower_id)
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


func _get_available_tower_buttons_for_element(element: Element.enm) -> Array:
	var element_string: String = Element.convert_to_string(element)
	var tower_id_list = Properties.get_tower_id_list_by_filter(Tower.CsvProperty.ELEMENT, element_string)
	
	var res: Array = []
	for tower_id in tower_id_list:
		var tier: int = TowerProperties.get_tier(tower_id)
		var is_first_tier: bool = tier == 1
		var display_all_tower_tiers: bool = Config.display_all_tower_tiers()
		var tier_is_ok: bool = is_first_tier || display_all_tower_tiers

		if available_tower_buttons.has(tower_id) && tier_is_ok:
			res.append(tower_id)
	
	return res
