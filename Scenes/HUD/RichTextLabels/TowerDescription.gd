extends RichTextLabel


# Static description of a tower.
# It may contain icon of a tower and icons of
# every skill that the tower has.

@export var tower_id: int


func _ready():
	clear()
	var tower_info_text: String = _get_tower_text()
	append_text(tower_info_text)


func _get_tower_text() -> String:
	var text: String = ""

	var requirements_text: String = _get_tower_requirements_text(tower_id)
	var display_name: String = TowerProperties.get_display_name(tower_id)
	var cost: int = TowerProperties.get_cost(tower_id)
	var cost_ok: bool = GoldControl.get_gold() >= cost
	var cost_string: String = _get_colored_requirement_number(cost, cost_ok)
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
	specials_text = _add_color_to_numbers(specials_text)
	var extra_text: String = tower.get_extra_tooltip_text()
	extra_text = _add_color_to_numbers(extra_text)
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
		var autocast_description: String = autocast.description
		autocast_description = _add_color_to_numbers(autocast_description)
		text += " \n%s\n" % autocast_description
	
	return text


func _get_tower_requirements_text(tower_id: int) -> String:
	var text: String = ""

	var satisfied: bool = TowerProperties.requirements_are_satisfied(tower_id)

	if satisfied:
		return ""

	var required_wave_level: int = TowerProperties.get_required_wave_level(tower_id)
	var wave_level_ok: bool = TowerProperties.wave_level_foo(tower_id)
	var wave_level_string: String = _get_colored_requirement_number(required_wave_level, wave_level_ok)

	var required_element_level: int = TowerProperties.get_required_element_level(tower_id)
	var element_level_ok: bool = TowerProperties.element_level_foo(tower_id)
	var element_level_string: String = _get_colored_requirement_number(required_element_level, element_level_ok)

	var element_string: String = TowerProperties.get_element_string(tower_id)

	text += "[color=GOLD][b]Requirements[/b][/color]\n"
	text += "Wave level: %s\n" % wave_level_string
	text += "%s research level: %s\n" % [element_string.capitalize(), element_level_string]
	
	return text


# Adds gold color to all ints and floats in the text.
func _add_color_to_numbers(text: String) -> String:
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


func _get_colored_requirement_number(value: int, requirement_satisfied: bool) -> String:
	var color: Color
	if requirement_satisfied:
		color = Color.GOLD
	else:
		color = Color.ORANGE_RED

	var string: String = "[color=%s]%d[/color]" % [color.to_html(), value]

	return string
