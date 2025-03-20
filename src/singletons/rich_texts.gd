extends Node


func get_tower_specials_text(tower_id: int) -> String:
	var text: String = ""

	var attack_target_type: TargetType = TowerProperties.get_attack_target_type(tower_id)
	var attacks_ground_only: bool = attack_target_type.equals_to(Tower.TARGET_TYPE_GROUND_ONLY)
	var attacks_air_only: bool = attack_target_type.equals_to(Tower.TARGET_TYPE_AIR_ONLY)
	if attacks_ground_only:
		text += "[color=RED]Attacks GROUND only[/color]\n"
	elif attacks_air_only:
		text += "[color=RED]Attacks AIR only[/color]\n"

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

	var text: String = "Attacks up to [color=GOLD]%d[/color] targets at the same time.\n" % multishot_count

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
		var splash_percentage: int = floor(splash_ratio * 100)
		text += "[color=GOLD]%d[/color] AoE: [color=GOLD]%d%%[/color] damage\n" % [splash_range, splash_percentage]

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
		text = "[color=GOLD]%d[/color] targets\n" % bounce_count \
		+ "[color=GOLD]-%s[/color] damage per bounce\n" % bounce_dmg_percent
	else:
		text = "[color=GOLD]%d[/color] targets\n" % bounce_count

	return text


func get_research_text(element: Element.enm, player: Player) -> String:
	var text: String = ""
	
	var current_element_level = player.get_element_level(element)
	var reached_max_level: bool = current_element_level == Constants.MAX_ELEMENT_LEVEL
	if reached_max_level:
		return "Can't research any further.\n"

	var element_string: String = Element.convert_to_colored_string(element)
	var flavor_text: String = Element.get_flavor_text(element)
	var main_attack_types: String = Element.get_main_attack_types(element)
	var research_level: String = get_research_level_label(element, player)
	var cost: int = player.get_research_cost(element)
	var can_afford: bool = player.can_afford_research(element)
	var cost_string: String = get_colored_requirement_number(cost, can_afford)

	var explanation_text: String = ""
	match Globals.get_game_mode():
		GameMode.enm.BUILD: explanation_text = "Research next element level to unlock new towers of this element and to unlock upgrades for existing towers.\n"
		GameMode.enm.RANDOM_WITH_UPGRADES: explanation_text = "Research next element level to unlock new towers of this element and to upgrade existing towers to higher tiers.\n"
		GameMode.enm.TOTALLY_RANDOM: explanation_text = "Research next element level to unlock new towers of this element.\n"

	text += "Research %s level %s\n" % [element_string, research_level] \
	+ "[img=32x32]res://resources/icons/hud/knowledge_tome.tres[/img] %s\n" % cost_string \
	+ " \n" \
	+ explanation_text \
	+ "[color=LIGHTBLUE]%s[/color]\n" % flavor_text \
	+ " \n" \
	+ "[color=GOLD]Main attack types:[/color] %s\n" % main_attack_types

	return text


func get_research_level_label(element: Element.enm, player: Player) -> String:
	var text: String = ""
	
	var current_element_level = player.get_element_level(element)
	var max_element_level = Constants.MAX_ELEMENT_LEVEL
	if current_element_level >= max_element_level:
		text += " [color=GOLD]MAX[/color] "
	else:
		text += "[color=GOLD]%s[/color]" % [current_element_level + 1]
	
	return text

func get_creep_info(creep: Creep) -> String:
	var text: String = ""

	var health_string_colored: String = _get_creep_health_string(creep)
	var mana: int = floor(creep.get_mana())
	var overall_mana: int = floor(creep.get_overall_mana())

	text += "[color=YELLOW]Health:[/color] %s\n" % [health_string_colored]
	if overall_mana > 0:
		text += "[color=YELLOW]Mana:[/color] [color=CORNFLOWER_BLUE]%d/%d[/color]\n" % [mana, overall_mana]

	var category: CreepCategory.enm = creep.get_category()
	var category_string: String = CreepCategory.convert_to_colored_string(category)
	var creep_size: CreepSize.enm = creep.get_size()
	var creep_size_string: String = CreepSize.convert_to_colored_string(creep_size)
	var armor_type: ArmorType.enm = creep.get_armor_type()
	var armor_type_string: String = ArmorType.convert_to_colored_string(armor_type)
	var armor: float = creep.get_base_armor()
	var armor_string: String = Utils.format_float(armor, 2)
	var armor_bonus: float = creep.get_overall_armor_bonus()
	
	var armor_bonus_string: String
	if armor_bonus > 0:
		armor_bonus_string = "+%s" % Utils.format_float(armor_bonus, 2)
	elif armor_bonus < 0:
		armor_bonus_string = "%s" % Utils.format_float(armor_bonus, 2)
	else:
		armor_bonus_string = ""

	text += "[color=YELLOW]Race:[/color] %s\n" % category_string
	text += "[color=YELLOW]Size:[/color] %s\n" % creep_size_string
	text += "[color=YELLOW]Armor type:[/color] %s\n" % armor_type_string
	text += "[color=YELLOW]Armor:[/color] [color=GOLD]%s[/color] %s\n" % [armor_string, armor_bonus_string]
	
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
		text += "[img=32x32]res://resources/icons/hud/gold.tres[/img] %s [img=32x32]res://resources/icons/hud/knowledge_tome.tres[/img] %s [img=32x32]res://resources/icons/hud/tower_food.tres[/img] [color=GOLD]%s[/color]\n" % [gold_cost_string, tome_cost_string, food_cost_string]
	else:
		text += "[img=32x32]res://resources/icons/hud/gold.tres[/img] %s [img=32x32]res://resources/icons/hud/tower_food.tres[/img] [color=GOLD]%s[/color]\n" % [gold_cost_string, food_cost_string]
	
	text += "[color=LIGHT_BLUE]%s[/color]\n" % description
	text += "[color=YELLOW]Author:[/color] %s\n" % author
	text += "[color=YELLOW]Element:[/color] %s\n" % element_string
	if attack_enabled:
		text += "[color=YELLOW]Attack:[/color] [color=GOLD]%d[/color] DPS, %s, [color=GOLD]%d[/color] range\n" % [dps, attack_type_string, attack_range]

	if mana > 0:
		text += "[color=YELLOW]Mana:[/color] [color=CORNFLOWER_BLUE]%d[/color] ([color=CORNFLOWER_BLUE]+%d[/color]/sec)\n" % [mana, mana_regen]
	
	text += " \n"

	if !ability_text.is_empty():
		text += ability_text \
		+ " \n"
	
	text = text.trim_suffix(" \n")

	return text


func get_tower_ability_text_short(tower_id: int) -> String:
	var text: String = ""

	var specials_text: String = get_tower_specials_text(tower_id)
	if !specials_text.is_empty():
		text += "[color=GOLD]Specials[/color]\n" \
		+ specials_text \
		+ " \n"

	var splash_text: String = get_tower_splash_attack_text(tower_id)
	if !splash_text.is_empty():
		text += "[color=GOLD]Splash Attack[/color]\n" \
		+ splash_text \
		+ " \n"

	var bounce_text: String = get_tower_bounce_attack_text(tower_id)
	if !bounce_text.is_empty():
		text += "[color=GOLD]Bounce Attack[/color]\n" \
		+ bounce_text \
		+ " \n"

	var multishot_text: String = get_tower_multishot_text(tower_id)
	if !multishot_text.is_empty():
		text += "[color=GOLD]Multishot[/color]\n" \
		+ multishot_text \
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
	var element_string: String = Element.convert_to_string(element)

	text += "[color=GOLD][b]Requirements[/b][/color]\n" \
	+ "Wave level: %s\n" % wave_level_string \
	+ "%s research level: %s\n" % [element_string.capitalize(), element_level_string]
	
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
	var is_disabled: bool = Item.disabled_item_list.has(item_id)

	var specials_text: String = item.get_specials_tooltip_text()
	specials_text = add_color_to_numbers(specials_text)

	text += "[b]%s[/b]\n" % display_name_colored \
	+ "[color=LIGHT_BLUE]%s[/color]\n" % description \
	+ "[color=YELLOW]Level:[/color] %s\n" % level \
	+ "[color=YELLOW]Author:[/color] %s\n" % author \
	+ " \n"

	if !specials_text.is_empty():
		text += "[color=YELLOW]Effects:[/color]\n" \
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
			text += "[color=YELLOW]Shift Right Click to toggle automatic casting.[/color]\n"
		
		text += "[color=YELLOW]Right Click to use item.[/color]\n" \
		+ " \n"

	if is_consumable:
		text += "[color=ORANGE]Right Click to use item. Item is consumed after use.[/color]\n" \
		+ " \n"

	if is_oil:
		text += "[color=ORANGE]Use oil on a tower to alter it permanently. The effects stay when the tower is transformed or upgraded![/color]\n" \
		+ " \n"

	if is_disabled:
		text += "[color=RED]THIS ITEM IS DISABLED[/color]\n" \
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


func get_aura_text_short(aura_id: int) -> String:
	var aura_name: String = AuraProperties.get_aura_name(aura_id)
	var description: String = AuraProperties.get_description_short(aura_id)
	description = add_color_to_numbers(description)

	var text: String = ""
	text += "[color=GOLD]%s - Aura[/color]\n" % aura_name
	text += "%s\n" % description

	return text


func get_autocast_text_long(autocast: Autocast) -> String:
	var autocast_name: String = autocast.get_autocast_name()
	var autocast_description_long: String = autocast.get_description_long()
	autocast_description_long = add_color_to_numbers(autocast_description_long)
	var stats_text: String = get_autocast_stats_text(autocast)

	var text: String = ""
	text += "[color=GOLD]%s[/color]\n" % autocast_name
	text += " \n"
	text += "%s\n" % autocast_description_long
	text += "%s\n" % stats_text

	return text


func get_autocast_text_short(autocast_id: int) -> String:
	var autocast_name: String = AutocastProperties.get_autocast_name(autocast_id)
	var autocast_description_short: String = AutocastProperties.get_description_short(autocast_id)
	autocast_description_short = add_color_to_numbers(autocast_description_short)
	var stats_text: String = get_autocast_stats_text_from_autocast_id(autocast_id)

	var text: String = "[color=GOLD]%s[/color]\n" % autocast_name \
	+ "%s\n" % autocast_description_short \
	+ "%s\n" % stats_text

	return text


func get_autocast_tooltip(autocast: Autocast) -> String:
	var text: String = ""

	text += RichTexts.get_autocast_text_long(autocast)
	text += " \n"

	if autocast.can_use_auto_mode():
		text += "[color=YELLOW]Right Click to toggle automatic casting on and off[/color]\n"
		text += " \n"

	text += "[color=YELLOW]Left Click to cast ability[/color]\n"

	return text


func get_autocast_stats_text(autocast: Autocast) -> String:
	var mana_cost: int = autocast.get_mana_cost()
	var cast_range: float = autocast.get_cast_range()
	var cooldown: float = autocast.get_cooldown()
	var text: String = get_autocast_stats_text_helper(mana_cost, cast_range, cooldown)

	return text


func get_autocast_stats_text_from_autocast_id(autocast_id: int) -> String:
	var mana_cost: int = AutocastProperties.get_mana_cost(autocast_id)
	var cast_range: float = AutocastProperties.get_cast_range(autocast_id)
	var cooldown: float = AutocastProperties.get_cooldown(autocast_id)
	var text: String = get_autocast_stats_text_helper(mana_cost, cast_range, cooldown)

	return text


func get_autocast_stats_text_helper(mana_cost: int, cast_range: float, cooldown: float) -> String:
	var mana_cost_string: String = "Mana cost: %s" % str(mana_cost)
	var cast_range_string: String = "%s range" % str(cast_range)
	var cooldown_string: String = "%ss cooldown" % str(cooldown)

	var text: String = ""

	var stats_list: Array[String] = []
	if mana_cost > 0:
		stats_list.append(mana_cost_string)
	if cast_range > 0:
		stats_list.append(cast_range_string)
	if cooldown > 0:
		stats_list.append(cooldown_string)

	if !stats_list.is_empty():
		var stats_line: String = ", ".join(stats_list) + "\n";
		stats_line = add_color_to_numbers(stats_line)
		text += " \n"
		text += stats_line

	return text


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
