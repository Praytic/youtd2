extends Control


# Tooltip used to display tower/item details when their
# buttons are hovered by mouse. Note that this is different
# from native Control tooltip because this tooltip has rich
# text and is displayed at a certain position, not under
# mouse cursor.


@onready var _label: RichTextLabel = $PanelContainer/RichTextLabel


func _ready():
	EventBus.tower_button_mouse_entered.connect(_on_tower_button_mouse_entered)
	EventBus.tower_button_mouse_exited.connect(_on_tower_button_mouse_exited)
	EventBus.item_button_mouse_entered.connect(_on_item_button_mouse_entered)
	EventBus.item_button_mouse_exited.connect(_on_item_button_mouse_exited)

	EventBus.research_button_mouse_entered.connect(_on_research_button_mouse_entered)
	EventBus.research_button_mouse_exited.connect(_on_research_button_mouse_exited)


func _on_tower_button_mouse_entered(tower_id: int):
	show()

	_label.clear()

	var tower_info_text: String = _get_tower_text(tower_id)
	_label.append_text(tower_info_text)


func _on_tower_button_mouse_exited():
	hide()


func _on_item_button_mouse_entered(item_id: int):
	show()

	_label.clear()

	var tower_info_text: String = _get_item_text(item_id)
	_label.append_text(tower_info_text)


func _on_item_button_mouse_exited():
	hide()


func _on_research_button_mouse_entered(element: Tower.Element):
	show()

	_label.clear()

	var text: String = _get_research_text(element)
	_label.append_text(text)


func _on_research_button_mouse_exited():
	hide()


func _get_research_text(element: Tower.Element) -> String:
	var element_string: String = Tower.element_to_string(element)
	var current_level: int = ElementLevel.get_current(element)
	var next_level: int = current_level + 1
	var cost: int = ElementLevel.get_research_cost(element)

	var text: String = ""

	var can_afford: bool = ElementLevel.can_afford_research(element)
	var cost_number_color: String
	if can_afford:
		cost_number_color = "GOLD"
	else:
		cost_number_color = "RED"

	text += "Research %s level [color=GOLD]%d[/color]\n" % [element_string, next_level]
	text += "[img=32x32]res://Resources/Textures/knowledge_tome.tres[/img] [color=%s]%d[/color]\n" % [cost_number_color, cost]
	text += "Research next element level to unlock the ability to build new towers of this element and to new upgrade existing towers to next tiers.\n"

	return text


func _get_tower_text(tower_id: int) -> String:
	var text: String = ""

	var requirements_text: String = _get_tower_requirements_text(tower_id)
	var display_name: String = TowerProperties.get_display_name(tower_id)
	var cost: int = TowerProperties.get_cost(tower_id)
	var food: int = 0
	var description: String = TowerProperties.get_description(tower_id)
	var author: String = TowerProperties.get_author(tower_id)
	var element: String = TowerProperties.get_element_string(tower_id)
	var damage: int = TowerProperties.get_base_damage(tower_id)
	var cooldown: float = TowerProperties.get_base_cooldown(tower_id)
	var dps: int = floor(damage / cooldown)
	var attack_type: String = TowerProperties.get_attack_type_string(tower_id)
	var attack_range: int = floor(TowerProperties.get_range(tower_id))

# 	NOTE: creating a tower instance just to get the tooltip
# 	text is weird, but the alternatives are worse
	var tower: Tower = TowerManager.get_tower(tower_id)
	var specials_text: String = tower.get_specials_tooltip_text()
	specials_text = _add_color_to_numbers(specials_text)
	var extra_text: String = tower.get_extra_tooltip_text()
	extra_text = _add_color_to_numbers(extra_text)
	tower.queue_free()

	if !requirements_text.is_empty():
		text += "%s\n" % requirements_text

	text += "[b]%s[/b]\n" % display_name
	text += "[img=32x32]res://Resources/Textures/gold.tres[/img] [color=GOLD]%d[/color] [img=32x32]res://Resources/Textures/food.tres[/img] [color=GOLD]%d[/color]\n" % [cost, food]
	text += "[color=LIGHT_BLUE]%s[/color]\n" % description
	text += "[color=YELLOW]Author:[/color] %s\n" % author
	text += "[color=YELLOW]Element:[/color] %s\n" % element.capitalize()
	text += "[color=YELLOW]Attack:[/color] [color=GOLD]%d[/color] dps, %s, [color=GOLD]%d[/color] range\n" % [dps, attack_type.capitalize(), attack_range]

	if !specials_text.is_empty():
		text += " \n[color=YELLOW]Specials:[/color]\n"
		text += "%s\n" % specials_text

	if !extra_text.is_empty():
		text += " \n%s\n" % extra_text
	
	return text


func _get_tower_requirements_text(tower_id: int) -> String:
	var text: String = ""

	var required_wave_level: int = TowerProperties.get_required_wave_level(tower_id)
	var required_element_level: int = TowerProperties.get_required_element_level(tower_id)
	var element_string: String = TowerProperties.get_element_string(tower_id)

	var requirements_are_satisfied: bool = TowerProperties.requirements_are_satisfied(tower_id)

	if requirements_are_satisfied:
		return ""

	text += "[color=YELLO][b]Requirements[/b]\n"
	text += "Wave level: %s\n" % required_wave_level
	text += "%s research level: %s\n \n" % [element_string.capitalize(), required_element_level]
	
	return text


func _get_item_text(item_id: int) -> String:
	var text: String = ""

	var display_name: String = ItemProperties.get_display_name(item_id)
	var description: String = ItemProperties.get_description(item_id)
	var author: String = ItemProperties.get_author(item_id)
	var is_oil: bool = ItemProperties.get_is_oil(item_id)

	var item: Item = Item.make(item_id)
	var specials_text: String = item.get_specials_tooltip_text()
	specials_text = _add_color_to_numbers(specials_text)
	var extra_text: String = item.get_extra_tooltip_text()
	extra_text = _add_color_to_numbers(extra_text)
	item.queue_free()
	
	text += "[b]%s[/b]\n" % display_name
	text += "[color=LIGHT_BLUE]%s[/color]\n" % description
	text += "[color=YELLOW]Author:[/color] %s\n" % author

	if !specials_text.is_empty():
		text += " \n[color=YELLOW]Specials:[/color]\n"
		text += "%s\n" % specials_text

	if !extra_text.is_empty():
		text += " \n%s\n" % extra_text

	if is_oil:
		text += " \n[color=ORANGE]Oil items are lost on use.[/color]"
	
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
