extends Node


func get_research_text(element: Element.enm) -> String:
	var text: String = ""
	
	var element_string: String = Element.convert_to_colored_string(element)
	var research_level: String = get_research_level_label(element)
	var cost: int = ElementLevel.get_research_cost(element)
	var can_afford: bool = ElementLevel.can_afford_research(element)
	var cost_string: String = get_colored_requirement_number(cost, can_afford)

	text += "Research %s level %s\n" % [element_string, research_level]
	text += "[img=32x32]res://Resources/Textures/knowledge_tome.tres[/img] %s\n" % cost_string

	match Globals.game_mode:
		GameMode.enm.BUILD: text += "Research next element level to unlock new towers of this element and to upgrade existing towers to higher tiers.\n"
		GameMode.enm.RANDOM_WITH_UPGRADES: text += "Research next element level to unlock new towers of this element and to upgrade existing towers to higher tiers.\n"
		GameMode.enm.TOTALLY_RANDOM: text += "Research next element level to unlock new towers of this element.\n"

	return text


func get_research_level_label(element: Element.enm) -> String:
	var text: String = ""
	
	var current_element_level = ElementLevel.get_current(element)
	var max_element_level = ElementLevel.get_max()
	if current_element_level >= max_element_level:
		text += " [color=GOLD]MAX[/color] "
	else:
		text += "[color=GOLD]%s[/color]" % [current_element_level + 1]
	
	return text

func get_creep_info(creep: Creep) -> String:
	var text: String = ""

	var health: int = floor(creep.get_health())
	var overall_health: int = floor(creep.get_overall_health())
	var mana: int = floor(creep.get_mana())
	var overall_mana: int = floor(creep.get_overall_mana())
	var wave: int = creep.get_spawn_level()

	text += "[img=32x32]res://Resources/Textures/wave.tres[/img] %s\n" % wave
	text += "[color=LIGHT_BLUE]%s[/color]\n" % "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse non nulla nec nunc dictum sodales."
	text += "[color=YELLOW]Health:[/color] %d/%d\n" % [health, overall_health]
	text += "[color=YELLOW]Mana:[/color] %d/%d\n" % [mana, overall_mana]

	var category: CreepCategory.enm = creep.get_category() as CreepCategory.enm
	var category_string: String = CreepCategory.convert_to_colored_string(category)
	var armor_type: ArmorType.enm = creep.get_armor_type()
	var armor_type_string: String = ArmorType.convert_to_colored_string(armor_type)
	var armor: int = creep.get_base_armor()
	var armor_bonus: int = creep.get_overall_armor_bonus()
	var armor_bonus_string: String = (str(armor_bonus) if armor_bonus < 0 else "+" + str(armor_bonus)) if armor_bonus != 0 else ""
	var damage_reduction: float = creep.get_current_armor_damage_reduction()
	var damage_reduction_string: String = Utils.format_percent(damage_reduction, 0)

	text += "[color=YELLOW]Race:[/color] %s\n" % category_string
	text += "[color=YELLOW]Armor Type:[/color] %s\n" % armor_type_string
	text += "[color=YELLOW]Armor:[/color] %s %s\n" % [str(armor), armor_bonus_string]
	text += "[color=YELLOW]Damage Reduction:[/color] %s\n" % damage_reduction_string
	
	return text


func get_tower_info(tower_id: int) -> String:
	var text: String = ""

	var cost_string: String = str(TowerProperties.get_cost(tower_id))
	var food: int = FoodManager.FOOD_PER_TOWER
	var description: String = TowerProperties.get_description(tower_id)
	var author: String = TowerProperties.get_author(tower_id)
	var element: Element.enm = TowerProperties.get_element(tower_id)
	var element_string: String = Element.convert_to_colored_string(element)
	var damage: int = TowerProperties.get_base_damage(tower_id)
	var cooldown: float = TowerProperties.get_base_cooldown(tower_id)
	var dps: int = floor(damage / cooldown)
	var attack_type: AttackType.enm = TowerProperties.get_attack_type(tower_id)
	var attack_type_string: String = AttackType.convert_to_colored_string(attack_type)
	var attack_range: int = floor(TowerProperties.get_range(tower_id))

	text += "[img=32x32]res://Resources/Textures/gold.tres[/img] %s [img=32x32]res://Resources/Textures/food.tres[/img] [color=GOLD]%d[/color]\n" % [cost_string, food]
	text += "[color=LIGHT_BLUE]%s[/color]\n" % description
	text += "[color=YELLOW]Author:[/color] %s\n" % author
	text += "[color=YELLOW]Element:[/color] %s\n" % element_string
	text += "[color=YELLOW]Attack:[/color] [color=GOLD]%d[/color] dps, %s, [color=GOLD]%d[/color] range\n" % [dps, attack_type_string, attack_range]

	return text


func get_tower_text(tower_id: int) -> String:
	var text: String = ""

	var requirements_text: String = get_tower_requirements_text(tower_id)
	var display_name: String = TowerProperties.get_display_name(tower_id)
	var cost: int = TowerProperties.get_cost(tower_id)
	var cost_ok: bool = GoldControl.get_gold() >= cost
	var cost_string: String = get_colored_requirement_number(cost, cost_ok)
	var food: int = 0
	var description: String = TowerProperties.get_description(tower_id)
	var author: String = TowerProperties.get_author(tower_id)
	var element: Element.enm = TowerProperties.get_element(tower_id)
	var element_string: String = Element.convert_to_colored_string(element)
	var damage: int = TowerProperties.get_base_damage(tower_id)
	var cooldown: float = TowerProperties.get_base_cooldown(tower_id)
	var dps: int = floor(damage / cooldown)
	var attack_type: AttackType.enm = TowerProperties.get_attack_type(tower_id)
	var attack_type_string: String = AttackType.convert_to_colored_string(attack_type)
	var attack_range: int = floor(TowerProperties.get_range(tower_id))

# 	NOTE: creating a tower instance just to get the tooltip
# 	text is weird, but the alternatives are worse. Need to
# 	call tower_init() so that autocasts are setup and we can
# 	get their descriptions.
	var tower: Tower = TowerManager.get_tower(tower_id)
	tower.tower_init()
	var specials_text: String = tower.get_specials_tooltip_text()
	specials_text = add_color_to_numbers(specials_text)
	var extra_text: String = tower.get_extra_tooltip_text()
	extra_text = add_color_to_numbers(extra_text)
	tower.queue_free()

	if !requirements_text.is_empty():
		text += "%s\n" % requirements_text
		text += " \n"

	text += "[b]%s[/b]\n" % display_name
	text += "[img=32x32]res://Resources/Textures/gold.tres[/img] %s [img=32x32]res://Resources/Textures/food.tres[/img] [color=GOLD]%d[/color]\n" % [cost_string, food]
	text += "[color=LIGHT_BLUE]%s[/color]\n" % description
	text += "[color=YELLOW]Author:[/color] %s\n" % author
	text += "[color=YELLOW]Element:[/color] %s\n" % element_string
	text += "[color=YELLOW]Attack:[/color] [color=GOLD]%d[/color] dps, %s, [color=GOLD]%d[/color] range\n" % [dps, attack_type_string, attack_range]

	if !specials_text.is_empty():
		text += " \n[color=YELLOW]Specials:[/color]\n"
		text += "%s\n" % specials_text

	if !extra_text.is_empty():
		text += " \n%s\n" % extra_text

	for autocast in tower.get_autocast_list():
		var autocast_text: String = get_autocast_text(autocast)
		text += " \n"
		text += autocast_text
	
	return text


func get_tower_requirements_text(tower_id: int) -> String:
	var text: String = ""

	var requirements_are_satisfied: bool = TowerProperties.requirements_are_satisfied(tower_id)

	if requirements_are_satisfied:
		return ""

	var required_wave_level: int = TowerProperties.get_required_wave_level(tower_id)
	var wave_level_ok: bool = TowerProperties.wave_level_foo(tower_id)
	var wave_level_string: String = get_colored_requirement_number(required_wave_level, wave_level_ok)

	var required_element_level: int = TowerProperties.get_required_element_level(tower_id)
	var element_level_ok: bool = TowerProperties.element_level_foo(tower_id)
	var element_level_string: String = get_colored_requirement_number(required_element_level, element_level_ok)

	var element_string: String = TowerProperties.get_element_string(tower_id)

	text += "[color=GOLD][b]Requirements[/b][/color]\n"
	text += "Wave level: %s\n" % wave_level_string
	text += "%s research level: %s\n" % [element_string.capitalize(), element_level_string]
	
	return text


func get_item_text(item: Item) -> String:
	var text: String = ""

	var item_id: int = item.get_id()
	var display_name: String = ItemProperties.get_display_name(item_id)
	var rarity: Rarity.enm = ItemProperties.get_rarity_num(item_id)
	var rarity_color: Color = Rarity.get_color(rarity)
	var display_name_colored: String = Utils.get_colored_string(display_name, rarity_color)
	var description: String = ItemProperties.get_description(item_id)
	var author: String = ItemProperties.get_author(item_id)
	var is_oil: bool = ItemProperties.get_is_oil(item_id)
	var is_consumable: bool = ItemProperties.get_type(item_id) == ItemType.enm.CONSUMABLE

	var specials_text: String = item.get_specials_tooltip_text()
	specials_text = add_color_to_numbers(specials_text)
	var extra_text: String = item.get_extra_tooltip_text()
	extra_text = add_color_to_numbers(extra_text)

	text += "[b]%s[/b]\n" % display_name_colored
	text += "[color=LIGHT_BLUE]%s[/color]\n" % description
	text += "[color=YELLOW]Author:[/color] %s\n" % author

	if !specials_text.is_empty():
		text += " \n[color=YELLOW]Effects:[/color]\n"
		text += "%s\n" % specials_text

	if !extra_text.is_empty():
		text += " \n%s\n" % extra_text

	var autocast: Autocast = item.get_autocast()

	if autocast != null:
		var autocast_text: String = get_autocast_text(autocast)
		text += " \n"
		text += autocast_text

		var item_is_on_tower: bool = item.get_carrier() != null
		var is_manual_cast: bool = !autocast.can_use_auto_mode()

		if item_is_on_tower && is_manual_cast:
			text += " \n"
			text += "[color=YELLOW]Right Click to use item[/color]\n"

	if is_consumable:
		text += " \n[color=ORANGE]Right Click to use item. Item is consumed after use.[/color]"

	if is_oil:
		text += " \n[color=ORANGE]Use oil on a tower to alter it permanently. The effects stay when the tower is transformed or upgraded![/color]"
	
	return text


# Adds gold color to all ints and floats in the text.
func add_color_to_numbers(text: String) -> String:
	var colored_text: String = text

	var index: int = 0
	var tag_open: String = "[color=GOLD]"
	var tag_close: String = "[/color]"
	var tag_is_opened: bool = false

	while index < colored_text.length():
		var c: String = colored_text[index]
		var next: String
		if index + 1 < colored_text.length():
			next = colored_text[index + 1]
		else:
			next = ""

		if tag_is_opened:
			var c_is_valid_part_of_number: bool = c.is_valid_int() || c == "%" || c == "s"

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
			var c_is_valid_start_of_number: bool = c.is_valid_int() || ((c == "+" || c == "-") && next.is_valid_int())

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


func get_autocast_text(autocast: Autocast) -> String:
	var title: String = autocast.title
	var autocast_description: String = autocast.description
	autocast_description = add_color_to_numbers(autocast_description)
	var mana_cost: String = "Mana cost: %s" % str(autocast.mana_cost)
	var cast_range: String = "%s range" % str(autocast.cast_range)
	var autocast_cooldown: String = "%ss cooldown" % str(autocast.cooldown)

	var text: String = ""
	text += "[color=GOLD]%s[/color]\n" % title
	text += "%s\n" % autocast_description

	var stats_list: Array[String] = []
	if autocast.mana_cost > 0:
		stats_list.append(mana_cost)
	if autocast.cast_range > 0:
		stats_list.append(cast_range)
	if autocast.cooldown > 0:
		stats_list.append(autocast_cooldown)

	if !stats_list.is_empty():
		var stats_line: String = ", ".join(stats_list) + "\n";
		stats_line = add_color_to_numbers(stats_line)
		text += " \n"
		text += stats_line

	return text
