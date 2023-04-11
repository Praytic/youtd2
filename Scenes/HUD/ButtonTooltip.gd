extends Control


# Tooltip used to display tower/item details when their
# buttons are hovered by mouse. Note that this is different
# from native Control tooltip because this tooltip has rich
# text and is displayed at a certain position, not under
# mouse cursor.

# TODO: load info that can't be obtained from csv

@onready var _label: RichTextLabel = $PanelContainer/RichTextLabel
@onready var _gold_texture: Texture2D = load("res://Resources/Textures/gold.tres")
@onready var _food_texture: Texture2D = load("res://Resources/Textures/food.tres")


func set_tower_id(tower_id: int):
	_label.clear()

	_label.push_bold()
	var display_name: String = TowerProperties.get_display_name(tower_id)
	_label.append_text(display_name)
	_label.newline()
	_label.pop()

	var cost: int = TowerProperties.get_cost(tower_id)
	_label.add_image(_gold_texture, 32, 32)
	_label.append_text(" %d " % cost)
	_label.add_image(_food_texture, 32, 32)
	var food: int = 0
	_label.append_text(" %d" % food)
	_label.newline()

	_label.push_color(Color.LIGHT_BLUE)
	var description: String = TowerProperties.get_description(tower_id)
	_label.append_text(description)
	_label.newline()
	_label.pop()

	var author: String = TowerProperties.get_author(tower_id)
	_label.append_text("Author: %s" % author)
	_label.newline()

	var element: String = TowerProperties.get_element_string(tower_id)
	_label.append_text("Element: %s" % element.capitalize())
	_label.newline()

	var damage: int = TowerProperties.get_base_damage(tower_id)
	var cooldown: float = TowerProperties.get_base_cooldown(tower_id)
	var dps: int = floor(damage / cooldown)

	var attack_type: String = TowerProperties.get_attack_type_string(tower_id)

	var attack_range: int = floor(TowerProperties.get_range(tower_id))

	_label.append_text("Attack: %d dps, %s, %d range" % [dps, attack_type.capitalize(), attack_range])
	_label.newline()

# 	NOTE: creating a tower instance just to get the tooltip
# 	text is weird, but the alternatives are worse
	var tower: Tower = TowerManager.get_tower(tower_id)

	_label.append_text("Specials:")
	_label.newline()
	var specials_text: String = tower.get_specials_tooltip_text()
	_label.append_text(specials_text)
	_label.newline()

	var extra_text: String = tower.get_extra_tooltip_text()
	tower.queue_free()
	_label.append_text(extra_text)


func set_item_id(item_id: int):
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
	_label.append_text("Author: %s" % author)
	_label.newline()

	var item: Item = Item.make(item_id)

	_label.append_text("Specials:")
	_label.newline()

	var specials_text: String = item.get_specials_tooltip_text()
	_label.append_text(specials_text)
	_label.newline()

	var extra_text: String = item.get_extra_tooltip_text()
	_label.append_text(extra_text)

	item.queue_free()
