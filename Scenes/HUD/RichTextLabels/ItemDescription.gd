extends RichTextLabel


# Static description of a tower.
# It may contain icon of a tower and icons of
# every skill that the tower has.

@export var item: Item


func _ready():
	clear()
	var item_info_text: String = _get_item_text()
	append_text(item_info_text)


func _get_item_text() -> String:
	var text: String = ""

	var item_id: int = item.get_id()
	var display_name: String = ItemProperties.get_display_name(item_id)
	var rarity: Rarity.enm = ItemProperties.get_rarity_num(item_id)
	var rarity_color: Color = Rarity.get_color(rarity)
	var display_name_colored: String = Utils.get_colored_string(display_name, rarity_color)
	var description: String = ItemProperties.get_description(item_id)
	var author: String = ItemProperties.get_author(item_id)
	var is_oil: bool = ItemProperties.get_is_oil(item_id)

	var specials_text: String = item.get_specials_tooltip_text()
	specials_text = _add_color_to_numbers(specials_text)
	var extra_text: String = item.get_extra_tooltip_text()
	extra_text = _add_color_to_numbers(extra_text)

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
		var item_is_on_tower: bool = item.get_carrier() != null
		var is_manual_cast: bool = !autocast.can_use_auto_mode()

		if item_is_on_tower && is_manual_cast:
			text += " \n"
			text += "[color=YELLOW]Right Click to use item[/color]\n"

	if is_oil:
		text += " \n[color=ORANGE]Use oil on a tower to alter it permanently. The effects stay when the tower is transformed or upgraded![/color]"
	
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
