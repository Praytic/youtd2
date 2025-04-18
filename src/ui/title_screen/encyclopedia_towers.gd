extends VBoxContainer


# This is the towers tab of the Encyclopedia Menu. Shows
# tower buttons on left side and info about selected tower
# on right side.

signal close_pressed()

@export var _generic_tab: EncyclopediaGenericTab

var _button_list: Array[TowerButton] = []
var _button_to_searchable_name_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready() -> void:
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
		var searchable_name: String = _make_searchable_string(tower_name)
		
		_button_to_searchable_name_map[button] = searchable_name

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

	var gold_cost: int = TowerProperties.get_cost(tower_id)
	var tome_cost: int = TowerProperties.get_tome_cost(tower_id)
	var food_cost: int = TowerProperties.get_food_cost(tower_id)
	
	if tome_cost != 0:
		text += "[img=32x32]res://resources/icons/hud/gold.tres[/img] [color=GOLD]%s[/color] [img=32x32]res://resources/icons/hud/knowledge_tome.tres[/img] [color=GOLD]%s[/color] [img=32x32]res://resources/icons/hud/tower_food.tres[/img] [color=GOLD]%s[/color]\n" % [gold_cost, tome_cost, food_cost]
	else:
		text += "[img=32x32]res://resources/icons/hud/gold.tres[/img] %s [img=32x32]res://resources/icons/hud/tower_food.tres[/img] [color=GOLD]%s[/color]\n" % [gold_cost, food_cost]
	
	text += "[color=LIGHT_BLUE]%s[/color]\n" % description
	text += "[color=YELLOW]%s[/color] %s\n" % [tr("TOWER_TOOLTIP_AUTHOR"), author]
	text += "[color=YELLOW]%s[/color] %s\n" % [tr("TOWER_TOOLTIP_ELEMENT"), element_string]
	if attack_enabled:
		text += tr("TOWER_TOOLTIP_ATTACK").format({DPS = dps, ATTACK_TYPE = attack_type_string, RANGE = attack_range})
		text += "\n"

	if mana > 0:
		text += tr("TOWER_TOOLTIP_MANA").format({MANA_MAX = mana, MANA_REGEN = mana_regen})
		text += "\n"
	
	text += " \n"

	var ability_id_list: Array = TowerProperties.get_ability_id_list(tower_id)
	for ability_id in ability_id_list:
		var ability_text: String = _get_ability_text(ability_id)

		text += ability_text
		text += " \n"

	var aura_id_list: Array = TowerProperties.get_aura_id_list(tower_id)
	for aura_id in aura_id_list:
		var aura_text: String = _get_aura_text(aura_id)

		text += aura_text
		text += " \n"

	var autocast_id_list: Array = TowerProperties.get_autocast_id_list(tower_id)
	for autocast_id in autocast_id_list:
		var autocast_text: String = _get_autocast_text(autocast_id)

		text += autocast_text
		text += " \n"

	return text


func _get_ability_text(ability_id: int) -> String:
	var ability_name: String = AbilityProperties.get_ability_name(ability_id)
	var description: String = AbilityProperties.get_description_long(ability_id)
	description = RichTexts.add_color_to_numbers(description)

	var text: String = "[color=GOLD]%s[/color]\n%s" % [ability_name, description]

	return text


func _get_aura_text(aura_id: int) -> String:
	var aura_name: String = AuraProperties.get_aura_name(aura_id)
	var description: String = AuraProperties.get_description_long(aura_id)
	var description_colored: String = RichTexts.add_color_to_numbers(description)
	var text: String = "[color=GOLD]%s - %s[/color]\n%s" % [aura_name, Utils.tr("AURA_WORD_IN_TITLE"), description_colored]

	return text


func _get_autocast_text(autocast_id: int) -> String:
	var autocast_name: String = AutocastProperties.get_autocast_name(autocast_id)
	var description: String = RichTexts.get_autocast_text_long(autocast_id)
	var description_colored: String = RichTexts.add_color_to_numbers(description)
	
	var text: String = "[color=GOLD]%s[/color]\n%s" % [autocast_name, description_colored]

	return text


# Simplify string by removing non-significant characters.
# This makes the string searchable.
func _make_searchable_string(string: String) -> String:
	var result: String = string.replace(",", "")
	result = string.replace(" ", "")
	result = string.replace("-", "")
	result = result.to_lower()
	
	return result


#########################
###     Callbacks     ###
#########################

func _on_button_pressed(tower_id: int):
	_generic_tab.set_selected_tower_id(tower_id)
	
	var tower_name: String = TowerProperties.get_display_name(tower_id)
	_generic_tab.set_selected_name(tower_name)
	
	var text: String = _get_text_for_tower(tower_id)
	_generic_tab.set_info_text(text)


func _on_encyclopedia_generic_tab_search_text_changed(new_text: String) -> void:
	var search_text: String = new_text
	search_text = _make_searchable_string(search_text)
	
	for button in _button_list:
		var searchable_name: String = _button_to_searchable_name_map[button]
		var button_matches: bool = searchable_name.contains(search_text) || search_text.is_empty()
		
		button.visible = button_matches


func _on_encyclopedia_generic_tab_close_pressed() -> void:
	close_pressed.emit()
