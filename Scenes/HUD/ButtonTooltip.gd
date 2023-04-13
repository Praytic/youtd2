extends Control

signal test_signal()

# Tooltip used to display tower/item details when their
# buttons are hovered by mouse. Note that this is different
# from native Control tooltip because this tooltip has rich
# text and is displayed at a certain position, not under
# mouse cursor.

# TODO: load info that can't be obtained from csv

@onready var _label: RichTextLabel = $PanelContainer/RichTextLabel
@onready var _gold_texture: Texture2D = load("res://Resources/Textures/gold.tres")
@onready var _food_texture: Texture2D = load("res://Resources/Textures/food.tres")


func _ready():
	EventBus.tower_button_mouse_entered.connect(_on_tower_button_mouse_entered)
	EventBus.tower_button_mouse_exited.connect(_on_tower_button_mouse_exited)
	EventBus.item_button_mouse_entered.connect(_on_item_button_mouse_entered)
	EventBus.item_button_mouse_exited.connect(_on_item_button_mouse_exited)

	print("\n\nbutton tooltip test signal=", test_signal.get_connections())

func _on_tower_button_mouse_entered(tower_id: int):
	show()

	_label.clear()

	_label.push_bold()
	var display_name: String = TowerProperties.get_display_name(tower_id)
	_label.append_text(display_name)
	_label.newline()
	_label.pop()

	var cost: int = TowerProperties.get_cost(tower_id)
	_label.add_image(_gold_texture, 32, 32)
	_label.append_text(" [color=gold]%d[/color] " % cost)
	_label.add_image(_food_texture, 32, 32)
	var food: int = 0
	_label.append_text(" [color=gold]%d[/color]" % food)
	_label.newline()

	_label.push_color(Color.LIGHT_BLUE)
	var description: String = TowerProperties.get_description(tower_id)
	_label.append_text(description)
	_label.newline()
	_label.pop()

	var author: String = TowerProperties.get_author(tower_id)
	_label.append_text("[color=yellow]Author:[/color] %s" % author)
	_label.newline()

	var element: String = TowerProperties.get_element_string(tower_id)
	_label.append_text("[color=yellow]Element:[/color] %s" % element.capitalize())
	_label.newline()

	var damage: int = TowerProperties.get_base_damage(tower_id)
	var cooldown: float = TowerProperties.get_base_cooldown(tower_id)
	var dps: int = floor(damage / cooldown)

	var attack_type: String = TowerProperties.get_attack_type_string(tower_id)

	var attack_range: int = floor(TowerProperties.get_range(tower_id))

	_label.append_text("[color=yellow]Attack:[/color] [color=gold]%d[/color] dps, %s, [color=gold]%d[/color] range" % [dps, attack_type.capitalize(), attack_range])
	_label.newline()

# 	NOTE: creating a tower instance just to get the tooltip
# 	text is weird, but the alternatives are worse
	var tower: Tower = TowerManager.get_tower(tower_id)

	var specials_text: String = tower.get_specials_tooltip_text()

	if !specials_text.is_empty():
		_label.append_text("[color=yellow]Specials:[/color]")
		_label.newline()
		_label.append_text(specials_text)
		_label.newline()

	var extra_text: String = tower.get_extra_tooltip_text()
	extra_text = add_color_to_numbers(extra_text)
	tower.queue_free()
	_label.append_text(extra_text)


func _on_tower_button_mouse_exited():
	hide()


func _on_item_button_mouse_entered(item_id: int):
	show()

	_label.clear()

	_label.push_bold()
	var display_name: String = ItemProperties.get_display_name(item_id)
	_label.append_text(display_name)
	_label.newline()
	_label.pop()

	_label.push_color(Color.LIGHT_BLUE)
	var description: String = ItemProperties.get_description(item_id)
	_label.append_text(description)
	_label.newline()
	_label.pop()

	var author: String = ItemProperties.get_author(item_id)
	_label.append_text("[color=yellow]Author:[/color] %s" % author)
	_label.newline()

	var item: Item = Item.make(item_id)

	var specials_text: String = item.get_specials_tooltip_text()
	if !specials_text.is_empty():
		_label.append_text("[color=yellow]Specials:[/color]")
		_label.newline()

		_label.append_text(specials_text)
		_label.newline()

	var extra_text: String = item.get_extra_tooltip_text()
	extra_text = add_color_to_numbers(extra_text)
	_label.append_text(extra_text)

	item.queue_free()


func _on_item_button_mouse_exited():
	hide()


# Adds gold color to all numbers and floats in the text.
# Requirements:
# space, newline, +/- before
# space, newline, % after
func add_color_to_numbers(text: String) -> String:
	var split_by_space: PackedStringArray = text.split(" ")

	for i in range(0, split_by_space.size()):
		var outer_element: String = split_by_space[i]

		var split_by_newline: PackedStringArray = outer_element.split("\n")

		for j in range(0, split_by_newline.size()):
			var element: String = split_by_newline[j]

			var need_to_color: bool = element.is_valid_int() || element.is_valid_float() || element.ends_with("%")

			if need_to_color:
				split_by_newline[j] = "[color=gold]%s[/color]" % element

		split_by_space[i] = "\n".join(split_by_newline)

	var colored_text: String = " ".join(split_by_space)

	return colored_text
