class_name EncyclopediaGenericTab extends VBoxContainer


signal filter_changed()
signal close_pressed()


@export var _info_label: RichTextLabel
@export var _button_grid: GridContainer
@export var _selected_tower_button: TowerButton
@export var _selected_item_button: ItemButton
@export var _selected_name_label: Label
@export var _search_text_edit: LineEdit

@export var _item_type_filter_container: HBoxContainer
@export var _regular_check: CheckBox
@export var _oil_check: CheckBox
@export var _consumable_check: CheckBox

@export var _element_filter_container: HBoxContainer
@export var _ice_check: CheckBox
@export var _nature_check: CheckBox
@export var _fire_check: CheckBox
@export var _astral_check: CheckBox
@export var _darkness_check: CheckBox
@export var _iron_check: CheckBox
@export var _storm_check: CheckBox

@export var _ice_label: Label
@export var _nature_label: Label
@export var _fire_label: Label
@export var _astral_label: Label
@export var _darkness_label: Label
@export var _iron_label: Label
@export var _storm_label: Label

@export var _common_check: CheckBox
@export var _uncommon_check: CheckBox
@export var _rare_check: CheckBox
@export var _unique_check: CheckBox

@export var _common_label: Label
@export var _uncommon_label: Label
@export var _rare_label: Label
@export var _unique_label: Label

@onready var _item_type_check_map: Dictionary = {
	ItemType.enm.REGULAR: _regular_check,
	ItemType.enm.OIL: _oil_check,
	ItemType.enm.CONSUMABLE: _consumable_check,
}

@onready var _element_check_map: Dictionary = {
	Element.enm.ICE: _ice_check,
	Element.enm.NATURE: _nature_check,
	Element.enm.FIRE: _fire_check,
	Element.enm.ASTRAL: _astral_check,
	Element.enm.DARKNESS: _darkness_check,
	Element.enm.IRON: _iron_check,
	Element.enm.STORM: _storm_check,
}

@onready var _element_label_map: Dictionary = {
	Element.enm.ICE: _ice_label,
	Element.enm.NATURE: _nature_label,
	Element.enm.FIRE: _fire_label,
	Element.enm.ASTRAL: _astral_label,
	Element.enm.DARKNESS: _darkness_label,
	Element.enm.IRON: _iron_label,
	Element.enm.STORM: _storm_label,
}

@onready var _rarity_check_map: Dictionary = {
	Rarity.enm.COMMON: _common_check,
	Rarity.enm.UNCOMMON: _uncommon_check,
	Rarity.enm.RARE: _rare_check,
	Rarity.enm.UNIQUE: _unique_check,
}

@onready var _rarity_label_map: Dictionary = {
	Rarity.enm.COMMON: _common_label,
	Rarity.enm.UNCOMMON: _uncommon_label,
	Rarity.enm.RARE: _rare_label,
	Rarity.enm.UNIQUE: _unique_label,
}

#########################
###     Built-in      ###
#########################

func _ready() -> void:
	_selected_tower_button.hide()
	_selected_tower_button.set_tooltip_is_enabled(false)
	_selected_tower_button.set_tier_visible(true)
	
	_info_label.clear()
	_selected_name_label.text = ""
	
	for check in _item_type_check_map.values():
		check.toggled.connect(_on_item_type_check_toggled)
	
	for check in _element_check_map.values():
		check.toggled.connect(_on_element_check_toggled)
	
	for element in Element.get_list():
		var element_color: Color = Element.get_color(element)
		var element_label: Label = _element_label_map[element]
		element_label.set("theme_override_colors/font_color", element_color)

	for check in _rarity_check_map.values():
		check.toggled.connect(_on_rarity_check_toggled)
	
	for rarity in Rarity.get_list():
		var rarity_color: Color = Rarity.get_color(rarity)
		var rarity_label: Label = _rarity_label_map[rarity]
		rarity_label.set("theme_override_colors/font_color", rarity_color)


#########################
###       Public      ###
#########################

func set_item_type_filters_visible(value: bool):
	_item_type_filter_container.visible = value


func set_element_filters_visible(value: bool):
	_element_filter_container.visible = value


func add_button_to_grid(button: Button):
	_button_grid.add_child(button)


func set_selected_tower_id(tower_id: int):
	_selected_tower_button.set_tower_id(tower_id)
	_selected_tower_button.show()
	_selected_item_button.hide()


func set_selected_item_id(item_id: int):
	_selected_item_button.setup_button_for_encyclopedia(item_id)
	_selected_item_button.show()
	_selected_tower_button.hide()


func set_selected_name(selected_name: String):
	_selected_name_label.text = selected_name


func set_info_text(text: String):
	_info_label.clear()
	_info_label.append_text(text)


func get_item_type_filter() -> Array[ItemType.enm]:
	var item_type_filter_list: Array[ItemType.enm] = []
	
	for item_type in _item_type_check_map.keys():
		var check: CheckBox = _item_type_check_map[item_type]
		var item_type_is_included: bool = check.button_pressed
		
		if item_type_is_included:
			item_type_filter_list.append(item_type)
	
	if item_type_filter_list.is_empty():
		return ItemType.get_list()
	
	return item_type_filter_list


func get_element_filter() -> Array[Element.enm]:
	var element_filter_list: Array[Element.enm] = []
	
	for element in _element_check_map.keys():
		var check: CheckBox = _element_check_map[element]
		var element_is_included: bool = check.button_pressed
		
		if element_is_included:
			element_filter_list.append(element)
	
	if element_filter_list.is_empty():
		return Element.get_list()
	
	return element_filter_list


func get_rarity_filter() -> Array[Rarity.enm]:
	var rarity_filter_list: Array[Rarity.enm] = []
	
	for rarity in _rarity_check_map.keys():
		var check: CheckBox = _rarity_check_map[rarity]
		var rarity_is_included: bool = check.button_pressed
		
		if rarity_is_included:
			rarity_filter_list.append(rarity)
	
	if rarity_filter_list.is_empty():
		return Rarity.get_list()
	
	return rarity_filter_list


func get_search_text() -> String:
	return _search_text_edit.text


#########################
###     Callbacks     ###
#########################

func _on_close_button_pressed() -> void:
	close_pressed.emit()


func _on_search_box_text_changed(_new_text: String) -> void:
	filter_changed.emit()


func _on_item_type_check_toggled(_toggled_on: bool) -> void:
	filter_changed.emit()


func _on_element_check_toggled(_toggled_on: bool):
	filter_changed.emit()


func _on_rarity_check_toggled(_toggled_on: bool):
	filter_changed.emit()
