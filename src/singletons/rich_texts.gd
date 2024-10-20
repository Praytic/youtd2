extends Node


# This class contains various functions which generate rich
# texts for RichTextLabel's.


#########################
###       Public      ###
#########################

func get_tower_specials_text(tower_id: int) -> String:
	var text: String = ""

	var attack_target_type: TargetType = TowerProperties.get_attack_target_type(tower_id)
	var attacks_ground_only: bool = attack_target_type.equals_to(Tower.TARGET_TYPE_GROUND_ONLY)
	var attacks_air_only: bool = attack_target_type.equals_to(Tower.TARGET_TYPE_AIR_ONLY)
	if attacks_ground_only:
		text += "[color=RED]%s[/color]\n" % tr("TOWER_SPECIAL_ATTACKS_GROUND_ONLY")
	elif attacks_air_only:
		text += "[color=RED]%s[/color]\n" % tr("TOWER_SPECIAL_ATTACKS_AIR_ONLY")

	var specials_modifier: Modifier = TowerProperties.get_specials_modifier(tower_id)
	var modifier_text: String = specials_modifier.get_tooltip_text()
	modifier_text = RichTexts.add_color_to_numbers(modifier_text)

	if !modifier_text.is_empty():
		text += modifier_text \
		+ " \n"

	text = text.trim_suffix(" \n")

	return text


func get_tower_multishot_text(tower_id: int) -> String:
	var multishot_count: int = TowerProperties.get_multishot(tower_id)
	
	if multishot_count <= 1:
		return ""

	var text: String = tr("TOWER_MULTISHOT_TEXT").format({TARGET_COUNT = multishot_count})
	text += "\n"

	return text


func get_tower_splash_attack_text(tower_id: int) -> String:
	var splash_attack_map: Dictionary = TowerProperties.get_splash_attack(tower_id)

	if splash_attack_map.is_empty():
		return ""

	var text: String = ""

	var splash_range_list: Array = splash_attack_map.keys()
	splash_range_list.sort()

	for splash_range in splash_range_list:
		var splash_ratio: float = splash_attack_map[splash_range]
		var splash_percentage: String = Utils.format_percent(splash_ratio, 0)
		text += tr("TOWER_SPLASH_ATTACK_LINE").format({RANGE = splash_range, DAMAGE_RATIO = splash_percentage})
		text += "\n"

	return text


func get_tower_bounce_attack_text(tower_id: int) -> String:
	var bounce_attack_values: Array = TowerProperties.get_bounce_attack(tower_id)

	if bounce_attack_values.is_empty():
		return ""

	var bounce_count: int = bounce_attack_values[0]
	var bounce_multiplier: int = bounce_attack_values[1]

	var text: String = ""
	
	if bounce_multiplier != 0:
		var bounce_dmg_percent: String = Utils.format_percent(bounce_multiplier, 0)
		text = tr("TOWER_BOUNCE_ATTACK_TEXT_NORMAL").format({BOUNCE_COUNT = bounce_count, DAMAGE_RATIO = bounce_dmg_percent})
		text += "\n"
	else:
		text = tr("TOWER_BOUNCE_ATTACK_TEXT_WITHOUT_DAMAGE_RATIO").format({BOUNCE_COUNT = bounce_count})
		text += "\n"

	return text


func get_research_text(element: Element.enm, player: Player) -> String:
	var text: String = ""
	
	var current_element_level = player.get_element_level(element)
	var reached_max_level: bool = current_element_level == player.get_max_element_level()
	if reached_max_level:
		return tr("RESEARCH_ELEMENT_CANT_RESEARCH_FURTHER") + "\n"

	var element_string: String = Element.convert_to_colored_string(element)
	var flavor_text: String = Element.get_flavor_text(element)
	var main_attack_types: String = Element.get_main_attack_types(element)
	var research_level: String = get_research_level_label(element, player)
	var cost: int = player.get_research_cost(element)
	var can_afford: bool = player.can_afford_research(element)
	var cost_string: String = get_colored_requirement_number(cost, can_afford)

	var explanation_text: String = ""
	match Globals.get_game_mode():
		GameMode.enm.BUILD: explanation_text = tr("RESEARCH_ELEMENT_EXPLANATION_FOR_BUILD")
		GameMode.enm.RANDOM_WITH_UPGRADES: explanation_text = tr("RESEARCH_ELEMENT_EXPLANATION_FOR_RANDOM_WITH_UPGRADES")
		GameMode.enm.TOTALLY_RANDOM: explanation_text = tr("RESEARCH_ELEMENT_EXPLANATION_FOR_TOTALLY_RANDOM")

	text += tr("RESEARCH_ELEMENT_INFO").format({ELEMENT = element_string, LEVEL = research_level}) + "\n" \
	+ "[img=32x32]res://resources/icons/hud/knowledge_tome.tres[/img] %s\n" % cost_string \
	+ " \n" \
	+ explanation_text + "\n" \
	+ "[color=LIGHTBLUE]%s[/color]\n" % flavor_text \
	+ " \n" \
	+ "[color=GOLD]%s[/color] %s\n" % [tr("RESEARCH_ELEMENT_MAIN_ATTACK_TYPES"), main_attack_types]

	return text


func get_research_level_label(element: Element.enm, player: Player) -> String:
	var text: String = ""
	
	var current_element_level = player.get_element_level(element)
	var max_element_level = player.get_max_element_level()
	if current_element_level >= max_element_level:
		text += " [color=GOLD]%s[/color] " % tr("RESEARCH_ELEMENT_LEVEL_MAX")
	else:
		text += "[color=GOLD]%s[/color]" % [current_element_level + 1]
	
	return text


func get_tower_text(tower_id: int, player: Player) -> String:
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

	var ability_text = get_tower_ability_text_short(tower_id)
	var requirements_text = get_tower_requirements_text(tower_id, player)
	var display_name: String = TowerProperties.get_display_name(tower_id)
	var gold_cost: int = TowerProperties.get_cost(tower_id)
	var tome_cost: int = TowerProperties.get_tome_cost(tower_id)
	var food_cost: int = TowerProperties.get_food_cost(tower_id)
	var gold_cost_ok: bool = player.enough_gold_for_tower(tower_id)
	var tome_cost_ok: bool = player.enough_tomes_for_tower(tower_id)
	var food_cost_ok: bool = player.enough_food_for_tower(tower_id)
	var gold_cost_string: String = get_colored_requirement_number(gold_cost, gold_cost_ok)
	var tome_cost_string: String = get_colored_requirement_number(tome_cost, tome_cost_ok)
	var food_cost_string: String = get_colored_requirement_number(food_cost, food_cost_ok)
	
	var text = ""
	
	if !requirements_text.is_empty():
		text += "%s\n" % requirements_text
		text += " \n"

	text += "[b]%s[/b]\n" % display_name

	if tome_cost != 0:
		text += "[img=32x32]res://resources/icons/hud/gold.tres[/img] %s [img=32x32]res://resources/icons/hud/knowledge_tome.tres[/img] %s [img=32x32]res://resources/icons/hud/tower_food.tres[/img] %s\n" % [gold_cost_string, tome_cost_string, food_cost_string]
	else:
		text += "[img=32x32]res://resources/icons/hud/gold.tres[/img] %s [img=32x32]res://resources/icons/hud/tower_food.tres[/img] %s\n" % [gold_cost_string, food_cost_string]
	
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

	if !ability_text.is_empty():
		text += ability_text \
		+ " \n"
	
	text = text.trim_suffix(" \n")

	return text


func get_tower_specials_and_extra_text(tower_id: int) -> String:
	var text: String = ""

	var specials_text: String = get_tower_specials_text(tower_id)
	if !specials_text.is_empty():
		text += "[color=GOLD]%s[/color]\n" % tr("TOWER_SPECIALS_TITLE") \
		+ specials_text \
		+ " \n"

	var splash_text: String = get_tower_splash_attack_text(tower_id)
	if !splash_text.is_empty():
		text += "[color=GOLD]%s[/color]\n" % tr("TOWER_SPLASH_ATTACK_TITLE") \
		+ splash_text \
		+ " \n"

	var bounce_text: String = get_tower_bounce_attack_text(tower_id)
	if !bounce_text.is_empty():
		text += "[color=GOLD]%s[/color]\n" % tr("TOWER_BOUNCE_ATTACK_TITLE") \
		+ bounce_text \
		+ " \n"

	var multishot_text: String = get_tower_multishot_text(tower_id)
	if !multishot_text.is_empty():
		text += "[color=GOLD]%s[/color]\n" % tr("TOWER_MULTISHOT_TITLE") \
		+ multishot_text \
		+ " \n"

	text = text.trim_suffix(" \n")

	return text


func get_tower_ability_text_short(tower_id: int) -> String:
	var text: String = ""

	var specials_and_extra_text: String = get_tower_specials_and_extra_text(tower_id)
	if !specials_and_extra_text.is_empty():
		text += specials_and_extra_text \
		+ " \n"

	var ability_id_list: Array = TowerProperties.get_ability_id_list(tower_id)
	for ability_id in ability_id_list:
		var ability_text: String = get_ability_text_short(ability_id)
		text += ability_text \
		+ " \n"

	var aura_id_list: Array = TowerProperties.get_aura_id_list(tower_id)
	for aura_id in aura_id_list:
		var aura_text: String = get_aura_text_short(aura_id)
		text += aura_text \
		+ " \n"

	var autocast_id_list: Array = TowerProperties.get_autocast_id_list(tower_id)
	for autocast_id in autocast_id_list:
		var autocast_text: String = get_autocast_text_short(autocast_id)
		text += autocast_text \
		+ " \n"

	text = text.trim_suffix(" \n")
	
	return text


func get_tower_requirements_text(tower_id: int, player: Player) -> String:
	var text: String = ""

	var requirements_are_satisfied: bool = TowerProperties.requirements_are_satisfied(tower_id, player)

	if requirements_are_satisfied:
		return ""

	var required_wave_level: int = TowerProperties.get_required_wave_level(tower_id)
	var wave_level_ok: bool = TowerProperties.wave_level_foo(tower_id, player)
	var wave_level_string: String = get_colored_requirement_number(required_wave_level, wave_level_ok)

	var required_element_level: int = TowerProperties.get_required_element_level(tower_id)
	var element_level_ok: bool = TowerProperties.element_level_foo(tower_id, player)
	var element_level_string: String = get_colored_requirement_number(required_element_level, element_level_ok)

	var element: Element.enm = TowerProperties.get_element(tower_id)
	var element_string: String = Element.get_display_string(element)

	text += tr("TOWER_TOOLTIP_REQUIREMENTS").format({WAVE_LEVEL = wave_level_string, ELEMENT = element_string, ELEMENT_LEVEL = element_level_string})
	text += "\n"
	
	return text


func get_item_text(item: Item) -> String:
	var text: String = ""

	var item_id: int = item.get_id()
	var display_name: String = ItemProperties.get_display_name(item_id)
	var rarity: Rarity.enm = ItemProperties.get_rarity(item_id)
	var rarity_color: Color = Rarity.get_color(rarity)
	var display_name_colored: String = Utils.get_colored_string(display_name, rarity_color)
	var description: String = ItemProperties.get_description(item_id)
	var level: int = ItemProperties.get_required_wave_level(item_id)
	var author: String = ItemProperties.get_author(item_id)
	var is_oil: bool = ItemProperties.get_is_oil(item_id)
	var is_consumable: bool = ItemProperties.is_consumable(item_id)

	var specials_text: String = item.get_specials_tooltip_text()
	specials_text = add_color_to_numbers(specials_text)

	text += "[b]%s[/b]\n" % display_name_colored \
	+ "[color=LIGHT_BLUE]%s[/color]\n" % description \
	+ "[color=YELLOW]%s[/color] %s\n" % [tr("ITEM_TOOLTIP_LEVEL"), level] \
	+ "[color=YELLOW]%s[/color] %s\n" % [tr("TOWER_TOOLTIP_AUTHOR"), author] \
	+ " \n"

	if !specials_text.is_empty():
		text += "[color=YELLOW]%s[/color]\n" % tr("ITEM_TOOLTIP_EFFECTS") \
		+ specials_text \
		+ " \n"

	var ability_id_list: Array = ItemProperties.get_ability_id_list(item_id)
	for ability_id in ability_id_list:
		var ability_text: String = get_ability_text_short(ability_id)
		text += ability_text \
		+ " \n"

	var aura_id_list: Array = ItemProperties.get_aura_id_list(item_id)
	for aura_id in aura_id_list:
		var aura_text: String = get_aura_text_short(aura_id)
		text += aura_text \
		+ " \n"

	var autocast_id_list: Array = ItemProperties.get_autocast_id_list(item_id)
	for autocast_id in autocast_id_list:
		var autocast_text: String = get_autocast_text_short(autocast_id)
		text += autocast_text \
		+ " \n"

	var item_is_on_tower: bool = item.get_carrier() != null

	if !autocast_id_list.is_empty() && item_is_on_tower:
		var autocast_id: int = autocast_id_list[0]
		
		var can_use_auto_mode: bool = Autocast.can_use_auto_mode_for_id(autocast_id)
		if can_use_auto_mode:
			text += "[color=YELLOW]%s[/color]\n" % tr("ITEM_TOOLTIP_TOGGLE_CAST")
		
		text += "[color=YELLOW]%s[/color]\n" % tr("ITEM_TOOLTIP_USE_ITEM") \
		+ " \n"

	if is_consumable:
		text += "[color=ORANGE]%s[/color]\n" % tr("ITEM_TOOLTIP_USE_CONSUMABLE") \
		+ " \n"

	if is_oil:
		text += "[color=ORANGE]%s[/color]\n" % tr("ITEM_TOOLTIP_USE_OIL") \
		+ " \n"

	text = text.trim_suffix(" \n")

	return text


# Adds gold color to all ints and floats in the text.
# NOTE: cases like these need to be colored:
# "15%"
# "3s"
# "x0.04" (for crit damage)
# "+x0.04"
func add_color_to_numbers(text: String) -> String:
	var colored_text: String = text

	var index: int = 0
	var tag_open: String = "[color=GOLD]"
	var tag_close: String = "[/color]"
	var tag_is_opened: bool = false
	var inside_existing_tag: bool = false

	while index < colored_text.length():
		var c: String = colored_text[index]
		var string_before_c: String = colored_text.substr(0, index)

		if !inside_existing_tag && string_before_c.ends_with("[color="):
			inside_existing_tag = true

		var next: String
		if index + 1 < colored_text.length():
			next = colored_text[index + 1]
		else:
			next = ""

		if inside_existing_tag:
#			NOTE: color tags can contain numbers, for
#			example: [color=1e90ffff]foo[/color]. In such
#			cases, we do not color these numbers because
#			that would break the existing color tag.
			if string_before_c.ends_with("[/color]"):
				inside_existing_tag = false
		elif tag_is_opened:
			var c_is_valid_part_of_number: bool = c.is_valid_int() || c == "%" || c == "s" || c == "x"

			if c == ".":
				var dot_is_part_of_float: bool = next.is_valid_int()
				if !dot_is_part_of_float:
					colored_text = colored_text.insert(index, tag_close)
					index += tag_close.length()
					tag_is_opened = false
			elif !c_is_valid_part_of_number:
				colored_text = colored_text.insert(index, tag_close)
				index += tag_close.length()
				tag_is_opened = false
		else:
			var c_is_valid_start_of_number: bool = c.is_valid_int() || ((c == "+" || c == "-" || c == "x") && (next.is_valid_int() || next == "x"))

			if c_is_valid_start_of_number:
				colored_text = colored_text.insert(index, tag_open)
				index += tag_open.length()
				tag_is_opened = true

		index += 1

	if tag_is_opened:
		colored_text = colored_text.insert(index, tag_close)

	return colored_text


func get_colored_requirement_number(value: int, requirement_satisfied: bool) -> String:
	var color: Color
	if requirement_satisfied:
		color = Color.GOLD
	else:
		color = Color.ORANGE_RED

	var string: String = "[color=%s]%d[/color]" % [color.to_html(), value]

	return string


func get_ability_text_short(ability_id: int) -> String:
	var ability_name: String = AbilityProperties.get_ability_name(ability_id)
	var description: String = AbilityProperties.get_description_short(ability_id)
	description = add_color_to_numbers(description)

	var text: String = ""
	text += "[color=GOLD]%s[/color]\n" % ability_name
	text += "%s\n" % description

	return text


func get_ability_text_long(ability_id: int) -> String:
	var ability_name: String = AbilityProperties.get_ability_name(ability_id)
	var description: String = AbilityProperties.get_description_long(ability_id)
	description = add_color_to_numbers(description)

	var text: String = ""
	text += "[color=GOLD]%s[/color]\n" % ability_name
	text += "%s\n" % description

	return text


func get_aura_text_short(aura_id: int) -> String:
	var aura_name: String = AuraProperties.get_aura_name(aura_id)
	var description: String = AuraProperties.get_description_short(aura_id)
	description = add_color_to_numbers(description)

	var text: String = ""
	text += "[color=GOLD]%s - %s[/color]\n" % [aura_name, tr("AURA_WORD_IN_TITLE")]
	text += "%s\n" % description

	return text


func get_aura_text_long(aura_id: int) -> String:
	var aura_name: String = AuraProperties.get_aura_name(aura_id)
	var description: String = AuraProperties.get_description_long(aura_id)
	description = add_color_to_numbers(description)

	var text: String = ""
	text += "[color=GOLD]%s - %s[/color]\n" % [aura_name, tr("AURA_WORD_IN_TITLE")]
	text += "%s\n" % description

	return text


func get_autocast_text_long(autocast_id: int) -> String:
	var autocast_name: String = AutocastProperties.get_autocast_name(autocast_id)
	var autocast_description_long: String = AutocastProperties.get_description_long(autocast_id)
	autocast_description_long = add_color_to_numbers(autocast_description_long)
	var stats_text: String = get_autocast_stats_text(autocast_id)

	var text: String = ""
	text += "[color=GOLD]%s[/color]\n" % autocast_name
	text += "%s\n" % autocast_description_long
	text += " \n"
	text += "%s\n" % stats_text

	return text


func get_autocast_text_short(autocast_id: int) -> String:
	var autocast_name: String = AutocastProperties.get_autocast_name(autocast_id)
	var autocast_description_short: String = AutocastProperties.get_description_short(autocast_id)
	autocast_description_short = add_color_to_numbers(autocast_description_short)
	var stats_text: String = get_autocast_stats_text(autocast_id)

	var text: String = "[color=GOLD]%s[/color]\n" % autocast_name \
	+ "%s\n" % autocast_description_short \
	+ " \n" \
	+ "%s" % stats_text

	return text


func get_autocast_tooltip(autocast: Autocast) -> String:
	var text: String = ""

	text += RichTexts.get_autocast_text_long(autocast.get_id())
	text += " \n"

	if autocast.can_use_auto_mode():
		text += "[color=YELLOW]%s[/color]\n" % tr("AUTOCAST_TOOLTIP_TOGGLE_CAST")
		text += " \n"

	text += "[color=YELLOW]%s[/color]\n" % tr("AUTOCAST_TOOLTIP_CAST")

	return text


func get_autocast_stats_text(autocast_id: int) -> String:
	var mana_cost: int = AutocastProperties.get_mana_cost(autocast_id)
	var cast_range: float = AutocastProperties.get_cast_range(autocast_id)
	var cooldown: float = AutocastProperties.get_cooldown(autocast_id)
	var mana_cost_string: String = tr("AUTOCAST_TOOLTIP_MANA_COST").format({MANA_COST = str(mana_cost)})
	var cast_range_string: String = tr("AUTOCAST_TOOLTIP_RANGE").format({RANGE = str(cast_range)})
	var cooldown_string: String = tr("AUTOCAST_TOOLTIP_COOLDOWN").format({COOLDOWN = str(cooldown)})

	var text: String = ""

	var stats_list: Array[String] = []
	if mana_cost > 0:
		stats_list.append(mana_cost_string)
	if cast_range > 0:
		stats_list.append(cast_range_string)
	if cooldown > 0:
		stats_list.append(cooldown_string)

	if !stats_list.is_empty():
		var stats_line: String = ", ".join(stats_list)
		stats_line = add_color_to_numbers(stats_line)
		text += "%s\n" % stats_line

	return text


#########################
###      Private      ###
#########################

func _get_creep_health_string(creep: Creep) -> String:
	var health_color: Color
	var health_ratio: float = creep.get_health_ratio()
	if health_ratio > 0.3:
		health_color = Color.GREEN
	else:
		health_color = Color.RED

	var health: int = floor(creep.get_health())
	var overall_health: int = floor(creep.get_overall_health())
	var health_string: String = "%d/%d" % [health, overall_health]
	var health_string_colored: String = Utils.get_colored_string(health_string, health_color)

	return health_string_colored
