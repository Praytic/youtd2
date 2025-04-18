extends VBoxContainer


signal close_pressed()


var _button_list: Array[ItemButton] = []
var _button_to_searchable_name_map: Dictionary = {}
var _button_to_item_type_map: Dictionary = {}
var _button_to_rarity_map: Dictionary = {}

@export var _generic_tab: EncyclopediaGenericTab


#########################
###     Built-in      ###
#########################

func _ready() -> void:
	_generic_tab.set_element_filters_visible(false)
	
	var item_id_list: Array = ItemProperties.get_item_id_list()
	
	item_id_list.sort_custom(
		func (a: int, b: int) -> bool:
			var item_type_a: ItemType.enm = ItemProperties.get_type(a)
			var item_type_b: ItemType.enm = ItemProperties.get_type(b)
			var rarity_a: Rarity.enm = ItemProperties.get_rarity(a)
			var rarity_b: Rarity.enm = ItemProperties.get_rarity(b)
			var required_wave_a: int = ItemProperties.get_required_wave_level(a)
			var required_wave_b: int = ItemProperties.get_required_wave_level(b)
			
			if item_type_a != item_type_b:
				return item_type_a < item_type_b
			else:
				if item_type_a == ItemType.enm.REGULAR:
					if rarity_a != rarity_b:
						return rarity_a < rarity_b
					else:
						return required_wave_a < required_wave_b
				else:
					return a < b
			)
	
	for item_id in item_id_list:
		var button: ItemButton = ItemButton.make()
		_generic_tab.add_button_to_grid(button)
		button.set_horadric_lock_visible(false)
		button.setup_button_for_encyclopedia(item_id)
		
		_button_list.append(button)
		
		button.pressed.connect(_on_button_pressed.bind(item_id))
		
		var item_name: String = ItemProperties.get_display_name(item_id)
		button.tooltip_text = item_name

		var searchable_name: String = EncyclopediaTowers.make_searchable_string(item_name)
		var item_type: ItemType.enm = ItemProperties.get_type(item_id)
		var rarity: Rarity.enm = ItemProperties.get_rarity(item_id)
		_button_to_searchable_name_map[button] = searchable_name
		_button_to_item_type_map[button] = item_type
		_button_to_rarity_map[button] = rarity


#########################
###      Private      ###
#########################

func _get_text_for_item(item_id: int) -> String:
	var text: String = ""

	var description: String = ItemProperties.get_description(item_id)
	var level: int = ItemProperties.get_required_wave_level(item_id)
	var author: String = ItemProperties.get_author(item_id)

	var specials_modifier: Modifier = ItemProperties.get_specials_modifier(item_id)
	var specials_text: String = specials_modifier.get_tooltip_text()
	specials_text = RichTexts.add_color_to_numbers(specials_text)

	text += " \n"

	if !description.is_empty():
		text += "[color=LIGHT_BLUE]%s[/color]\n" % description \
		+ " \n"
	
	text += "[color=YELLOW]%s[/color] %s\n" % [tr("ITEM_TOOLTIP_LEVEL"), level] \
	+ "[color=YELLOW]%s[/color] %s\n" % [tr("TOWER_TOOLTIP_AUTHOR"), author] \
	+ " \n"

	if !specials_text.is_empty():
		text += "[color=YELLOW]%s[/color]\n" % tr("ITEM_TOOLTIP_EFFECTS") \
		+ specials_text \
		+ " \n"

	var ability_id_list: Array = ItemProperties.get_ability_id_list(item_id)
	for ability_id in ability_id_list:
		var ability_text: String = RichTexts.get_ability_text_long(ability_id)

		text += ability_text
		text += " \n"

	var aura_id_list: Array = ItemProperties.get_aura_id_list(item_id)
	for aura_id in aura_id_list:
		var aura_text: String = RichTexts.get_aura_text_long(aura_id)

		text += aura_text
		text += " \n"

	var autocast_id_list: Array = ItemProperties.get_autocast_id_list(item_id)
	for autocast_id in autocast_id_list:
		var autocast_text: String = RichTexts.get_autocast_text_long(autocast_id)

		text += autocast_text
		text += " \n"

	return text


#########################
###     Callbacks     ###
#########################

func _on_encyclopedia_generic_tab_close_pressed() -> void:
	close_pressed.emit()


func _on_button_pressed(item_id: int):
	_generic_tab.set_selected_item_id(item_id)
	
	var item_name: String = ItemProperties.get_display_name(item_id)
	_generic_tab.set_selected_name(item_name)
	
	var text: String = _get_text_for_item(item_id)
	_generic_tab.set_info_text(text)


func _on_encyclopedia_generic_tab_filter_changed() -> void:
	var empty_element_map: Dictionary = {}
	EncyclopediaTowers.update_filtering(_button_list, _generic_tab, _button_to_searchable_name_map, _button_to_item_type_map, _button_to_rarity_map, empty_element_map)
