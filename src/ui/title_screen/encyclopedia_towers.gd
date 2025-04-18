class_name EncyclopediaTowers extends VBoxContainer


# This is the towers tab of the Encyclopedia Menu. Shows
# tower buttons on left side and info about selected tower
# on right side.

signal close_pressed()

@export var _generic_tab: EncyclopediaGenericTab

var _button_list: Array[TowerButton] = []
var _button_to_searchable_name_map: Dictionary = {}
var _button_to_element_map: Dictionary = {}
var _button_to_rarity_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready() -> void:
	_generic_tab.set_item_type_filters_visible(false)
	
	var tower_id_list: Array = TowerProperties.get_tower_id_list()
	
#	This sort groups towers by element, rarity and family
	tower_id_list.sort_custom(
		func (a: int, b: int) -> bool:
			var element_a: Element.enm = TowerProperties.get_element(a)
			var element_b: Element.enm = TowerProperties.get_element(b)
			var family_a: int = TowerProperties.get_family(a)
			var family_b: int = TowerProperties.get_family(b)
			var family_cost_a: int = TowerProperties.get_cost(family_a)
			var family_cost_b: int = TowerProperties.get_cost(family_b)
			var tier_a: int = TowerProperties.get_tier(a)
			var tier_b: int = TowerProperties.get_tier(b)
			var rarity_a: int = TowerProperties.get_rarity(a)
			var rarity_b: int = TowerProperties.get_rarity(b)
			
			if family_a == family_b:
				return tier_a < tier_b
			elif element_a != element_b:
				return element_a < element_b
			elif rarity_a != rarity_b:
				return rarity_a < rarity_b
			elif family_cost_a == family_cost_b:
				return family_a < family_b
			else:
				return family_cost_a < family_cost_b
			)
	
	for tower_id in tower_id_list:
		var tower_button: TowerButton = TowerButton.make()
		tower_button.set_tower_id(tower_id)
		tower_button.set_tooltip_is_enabled(false)
		tower_button.set_tier_visible(true)
		_generic_tab.add_button_to_grid(tower_button)
		
		_button_list.append(tower_button)
	
	for button in _button_list:
		var tower_id: int = button.get_tower_id()
		button.pressed.connect(_on_button_pressed.bind(tower_id))

#	NOTE: need to cache searchable names ahead of time
#	because calculating them is a bit costly. Calculating
#	searchable names while searching would cause some lag.
	for button in _button_list:
		var tower_id: int = button.get_tower_id()
		var tower_name: String = TowerProperties.get_display_name(tower_id)
		var searchable_name: String = EncyclopediaTowers.make_searchable_string(tower_name)
		var element: Element.enm = TowerProperties.get_element(tower_id)
		var rarity: Rarity.enm = TowerProperties.get_rarity(tower_id)
		
		_button_to_searchable_name_map[button] = searchable_name
		_button_to_element_map[button] = element
		_button_to_rarity_map[button] = rarity

	for button in _button_list:
		var tower_id: int = button.get_tower_id()
		var tower_name: String = TowerProperties.get_display_name(tower_id)
		
		button.tooltip_text = tower_name


#########################
###      Private      ###
#########################

func _get_text_for_tower(tower_id: int) -> String:
	var text: String = ""
	
	var description: String = TowerProperties.get_description(tower_id)
	var author: String = TowerProperties.get_author(tower_id)
	var element: Element.enm = TowerProperties.get_element(tower_id)
	var element_string: String = Element.convert_to_colored_string(element)
	var dps: int = floori(TowerProperties.get_dps(tower_id))
	var attack_enabled: bool = TowerProperties.get_attack_enabled(tower_id)
	var attack_type: AttackType.enm = TowerProperties.get_attack_type(tower_id)
	var attack_type_string: String = AttackType.convert_to_colored_string(attack_type)
	var attack_range: int = floor(TowerProperties.get_range(tower_id))
	var mana: int = floor(TowerProperties.get_mana(tower_id))
	var mana_regen: int = floor(TowerProperties.get_mana_regen(tower_id))
	var specials_and_extra_text: String = RichTexts.get_tower_specials_and_extra_text(tower_id)

	var gold_cost: int = TowerProperties.get_cost(tower_id)
	var tome_cost: int = TowerProperties.get_tome_cost(tower_id)
	var food_cost: int = TowerProperties.get_food_cost(tower_id)
	
	if tome_cost != 0:
		text += "[img=32x32]res://resources/icons/hud/gold.tres[/img] [color=GOLD]%s[/color] [img=32x32]res://resources/icons/hud/knowledge_tome.tres[/img] [color=GOLD]%s[/color] [img=32x32]res://resources/icons/hud/tower_food.tres[/img] [color=GOLD]%s[/color]\n" % [gold_cost, tome_cost, food_cost]
	else:
		text += "[img=32x32]res://resources/icons/hud/gold.tres[/img] %s [img=32x32]res://resources/icons/hud/tower_food.tres[/img] [color=GOLD]%s[/color]\n" % [gold_cost, food_cost]
	
	text += " \n"
	
	if !description.is_empty():
		text += "[color=LIGHT_BLUE]%s[/color]\n" % description
		text += " \n"
	
	text += "[color=YELLOW]%s[/color] %s\n" % [tr("TOWER_TOOLTIP_AUTHOR"), author]
	text += "[color=YELLOW]%s[/color] %s\n" % [tr("TOWER_TOOLTIP_ELEMENT"), element_string]
	if attack_enabled:
		text += tr("TOWER_TOOLTIP_ATTACK").format({DPS = dps, ATTACK_TYPE = attack_type_string, RANGE = attack_range})
		text += "\n"

	if mana > 0:
		text += tr("TOWER_TOOLTIP_MANA").format({MANA_MAX = mana, MANA_REGEN = mana_regen})
		text += "\n"
	
	text += " \n"

	if !specials_and_extra_text.is_empty():
		text += specials_and_extra_text
		text += " \n"

	var ability_id_list: Array = TowerProperties.get_ability_id_list(tower_id)
	for ability_id in ability_id_list:
		var ability_text: String = RichTexts.get_ability_text_long(ability_id)

		text += ability_text
		text += " \n"

	var aura_id_list: Array = TowerProperties.get_aura_id_list(tower_id)
	for aura_id in aura_id_list:
		var aura_text: String = RichTexts.get_aura_text_long(aura_id)

		text += aura_text
		text += " \n"

	var autocast_id_list: Array = TowerProperties.get_autocast_id_list(tower_id)
	for autocast_id in autocast_id_list:
		var autocast_text: String = RichTexts.get_autocast_text_long(autocast_id)

		text += autocast_text
		text += " \n"

	return text


#########################
###     Callbacks     ###
#########################

func _on_button_pressed(tower_id: int):
	_generic_tab.set_selected_tower_id(tower_id)
	
	var tower_name: String = TowerProperties.get_display_name(tower_id)
	_generic_tab.set_selected_name(tower_name)
	
	var text: String = _get_text_for_tower(tower_id)
	_generic_tab.set_info_text(text)


func _on_encyclopedia_generic_tab_filter_changed() -> void:
	var empty_item_type_map: Dictionary = {}
	EncyclopediaTowers.update_filtering(_button_list, _generic_tab, _button_to_searchable_name_map, empty_item_type_map, _button_to_rarity_map, _button_to_element_map)


func _on_encyclopedia_generic_tab_close_pressed() -> void:
	close_pressed.emit()


#########################
###       Static      ###
#########################

# Simplify string by removing non-significant characters.
# This makes the string searchable.
static func make_searchable_string(string: String) -> String:
	var result: String = string.replace(",", "")
	result = string.replace(" ", "")
	result = string.replace("-", "")
	result = result.to_lower()
	
	return result


static func update_filtering(button_list: Array, generic_tab: EncyclopediaGenericTab, button_to_searchable_name_map: Dictionary, button_to_item_type_map: Dictionary, button_to_rarity_map: Dictionary, button_to_element_map: Dictionary):
	var item_type_filter_list: Array[ItemType.enm] = generic_tab.get_item_type_filter()
	var element_filter_list: Array[Element.enm] = generic_tab.get_element_filter()
	var rarity_filter_list: Array[Rarity.enm] = generic_tab.get_rarity_filter()
	var search_text: String = generic_tab.get_search_text()
	search_text = EncyclopediaTowers.make_searchable_string(search_text)
	
	for button in button_list:
		var searchable_name: String = button_to_searchable_name_map[button]
		var name_match: bool = searchable_name.contains(search_text) || search_text.is_empty()
		var item_type: ItemType.enm = button_to_item_type_map.get(button, ItemType.enm.REGULAR)
		var item_type_filter_match: bool
		if !button_to_item_type_map.is_empty():
			item_type_filter_match = item_type_filter_list.has(item_type)
		else:
			item_type_filter_match = true
		var element: Element.enm = button_to_element_map.get(button, Element.enm.NONE)
		var element_filter_match: bool
		if !button_to_element_map.is_empty():
			element_filter_match = element_filter_list.has(element)
		else:
			element_filter_match = true
		var rarity: Element.enm = button_to_rarity_map[button]
		var rarity_filter_match: bool = rarity_filter_list.has(rarity)
		var button_should_be_visible: bool = name_match && item_type_filter_match && element_filter_match && rarity_filter_match
		
		button.visible = button_should_be_visible
