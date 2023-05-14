extends Node


# NOTE: order is important to be able to compare
enum enm {
	MASS,
	NORMAL,
	AIR,
	CHAMPION,
	BOSS,
	CHALLENGE_MASS,
	CHALLENGE_BOSS,
}


func from_string(string: String) -> CreepSize.enm:
	var string_upper: String = string.to_upper()
	var size: CreepSize.enm = CreepSize.enm.get(string_upper)

	return size


func convert_to_string(type: CreepSize.enm) -> String:
	match type:
		CreepSize.enm.MASS: return "Mass"
		CreepSize.enm.NORMAL: return "Normal"
		CreepSize.enm.AIR: return "Air"
		CreepSize.enm.CHAMPION: return "Champion"
		CreepSize.enm.BOSS: return "Boss"
		CreepSize.enm.CHALLENGE_MASS: return "Challenge"
		CreepSize.enm.CHALLENGE_BOSS: return "Challenge"

	push_error("Unknown type: ", type)

	return "[unknown creep size]"


func convert_to_colored_string(type: CreepSize.enm) -> String:
	var string: String = convert_to_string(type)

	match type:
		CreepSize.enm.MASS: return "[color=ORANGE]%s[/color]" % string
		CreepSize.enm.NORMAL: return "[color=GREEN]%s[/color]" % string
		CreepSize.enm.AIR: return "[color=BLUE]%s[/color]" % string
		CreepSize.enm.CHAMPION: return "[color=PURPLE]%s[/color]" % string
		CreepSize.enm.BOSS: return "[color=RED]%s[/color]" % string
		CreepSize.enm.CHALLENGE_MASS: return "[color=GOLD]%s[/color]" % string
		CreepSize.enm.CHALLENGE_BOSS: return "[color=GOLD]%s[/color]" % string

	push_error("Unknown type: ", type)

	return "[unknown creep size]"


# TODO: figure out actual values
func get_default_item_chance(type: CreepSize.enm) -> float:
	match type:
		CreepSize.enm.MASS: return 0.05
		CreepSize.enm.NORMAL: return 0.10
		CreepSize.enm.AIR: return 0.10
		CreepSize.enm.CHAMPION: return 0.20
		CreepSize.enm.BOSS: return 0.50
		CreepSize.enm.CHALLENGE_MASS: return 0.10
		CreepSize.enm.CHALLENGE_BOSS: return 0.70

	push_error("Unhandled type: ", type)

	return 0.0


# TODO: figure out actual values
func get_default_item_quality(type: CreepSize.enm) -> float:
	match type:
		CreepSize.enm.MASS: return 0.0
		CreepSize.enm.NORMAL: return 0.0
		CreepSize.enm.AIR: return 0.0
		CreepSize.enm.CHAMPION: return 0.25
		CreepSize.enm.BOSS: return 0.25
		CreepSize.enm.CHALLENGE_MASS: return 0.25
		CreepSize.enm.CHALLENGE_BOSS: return 0.25

	push_error("Unhandled type: ", type)

	return 0.0