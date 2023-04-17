class_name Player extends Node

# Class representing the player that owns towers. Used for
# multiplayer purposes. 


@onready var floating_text_scene: PackedScene = preload("res://Scenes/FloatingText.tscn")
@onready var _floating_text_container: Node = get_tree().get_root().get_node("GameScene/Map/FloatingTextContainer")


func display_floating_text_color(text: String, unit: Unit, color: Color, time: float):
	var floating_text = floating_text_scene.instantiate()
	floating_text.text = text
	floating_text.color = color
	floating_text.duration = time
	floating_text.position = unit.position
	_floating_text_container.add_child(floating_text)


# TODO: figure out what are the mystery float parameters,
# probably related to tween
func display_floating_text_x(text: String, unit: Unit, color_r: int, color_g: int, color_b: int, color_a: int, _mystery_float_1: float, _mystery_float_2: float, time: float):
	var color: Color = Color(color_r * 255.0, color_g * 255.0, color_b * 255.0, color_a * 255.0)
	display_floating_text_color(text, unit, color, time)


# TODO: implement, not sure what the difference is between this and then _x version
func display_floating_text(text: String, unit: Unit, color_r: int, color_g: int, color_b: int):
	display_floating_text_x(text, unit, color_r, color_g, color_b, 255, 0.0, 0.0, 1.0)


func display_static_floating_text(text: String, unit: Unit, color_r: int, color_g: int, color_b: int, time: float):
	var floating_text = floating_text_scene.instantiate()
	floating_text.animated = false
	floating_text.text = text
	floating_text.color = Color(color_r / 255.0, color_g / 255.0, color_b / 255.0, 1.0)
	floating_text.duration = time
	floating_text.position = unit.position
	_floating_text_container.add_child(floating_text)


func display_small_floating_text(text: String, unit: Unit, color_r: int, color_g: int, color_b: int, _mystery_float: float):
	display_floating_text_x(text, unit, color_r, color_g, color_b, 255, 0.0, 0.0, 1.0)


# TODO: Move to the "owner" class that is returned by
# getOwner() when owner class is implemented
func give_gold(amount: int, unit: Unit, show_effect: bool, show_text: bool):
	GoldControl.add_gold(amount)

	if show_effect:
		var effect: int = Effect.create_simple_at_unit("gold effect path", unit)
		Effect.destroy_effect(effect)

	if show_text:
		var text: String
		if amount >= 0:
			text = "+%d" % amount
		else:
			text = "-%d" % amount

		var color: Color
		if amount >= 0:
			color = Color.GOLD
		else:
			color = Color.RED

		display_floating_text_color(text, unit, color, 1.0)
