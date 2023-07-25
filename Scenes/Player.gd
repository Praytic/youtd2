class_name Player extends Node

# Class representing the player that owns towers. Used for
# multiplayer purposes. 


@onready var _floating_text_container: Node = get_tree().get_root().get_node("GameScene/Map/FloatingTextContainer")


# TODO: not sure what the point of this f-n is. Leaving as
# is because it's used in original scripts.
# NOTE: Item.getThePlayer() in JASS
func get_the_player() -> Player:
	return self


# NOTE: player.getTeam() in JASS
func get_team() -> Player:
	return self


# NOTE: player.getLevel() in JASS
func get_level() -> int:
	var level: int = WaveLevel.get_current()

	return level


# NOTE: player.displayFloatingTextColor() in JASS
func display_floating_text_color(text: String, unit: Unit, color: Color, time: float):
	var floating_text = Globals.floating_text_scene.instantiate()
	floating_text.text = text
	floating_text.color = color
	floating_text.duration = time
	floating_text.position = unit.position
	_floating_text_container.add_child(floating_text)


# TODO: figure out what are the mystery float parameters,
# probably related to tween
# NOTE: player.displayFloatingTextX() in JASS
func display_floating_text_x(text: String, unit: Unit, color_r: int, color_g: int, color_b: int, color_a: int, _mystery_float_1: float, _mystery_float_2: float, time: float):
	var color: Color = Color(color_r * 255.0, color_g * 255.0, color_b * 255.0, color_a * 255.0)
	display_floating_text_color(text, unit, color, time)


# TODO: implement, not sure what the difference is between this and then _x version.
# _x probably adds an x offset to the start location of floating text
# NOTE: player.displayFloatingText() in JASS
func display_floating_text(text: String, unit: Unit, color_r: int, color_g: int, color_b: int):
	display_floating_text_x(text, unit, color_r, color_g, color_b, 255, 0.0, 0.0, 1.0)


func display_static_floating_text(text: String, unit: Unit, color_r: int, color_g: int, color_b: int, time: float):
	var floating_text = Globals.floating_text_scene.instantiate()
	floating_text.animated = false
	floating_text.text = text
	floating_text.color = Color(color_r / 255.0, color_g / 255.0, color_b / 255.0, 1.0)
	floating_text.duration = time
	floating_text.position = unit.position
	_floating_text_container.add_child(floating_text)


# NOTE: player.displaySmallFloatingText() in JASS
func display_small_floating_text(text: String, unit: Unit, color_r: int, color_g: int, color_b: int, _mystery_float: float):
	display_floating_text_x(text, unit, color_r, color_g, color_b, 255, 0.0, 0.0, 1.0)


# TODO: Move to the "owner" class that is returned by
# getOwner() when owner class is implemented
# NOTE: player.giveGold() in JASS
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


# TODO: implement
# NOTE: player.modifyInterestRate in JASS
func modify_interest_rate(_amount: float):
	pass
