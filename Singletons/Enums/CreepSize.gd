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


const _string_map: Dictionary = {
	CreepSize.enm.MASS: "mass",
	CreepSize.enm.NORMAL: "normal",
	CreepSize.enm.AIR: "air",
	CreepSize.enm.CHAMPION: "champion",
	CreepSize.enm.BOSS: "boss",
	CreepSize.enm.CHALLENGE_MASS: "challenge",
	CreepSize.enm.CHALLENGE_BOSS: "challenge",
}


const _color_map: Dictionary = {
	CreepSize.enm.MASS: Color.ORANGE,
	CreepSize.enm.NORMAL: Color.DARK_SEA_GREEN,
	CreepSize.enm.AIR: Color.CORNFLOWER_BLUE,
	CreepSize.enm.CHAMPION: Color.REBECCA_PURPLE,
	CreepSize.enm.BOSS: Color.ORANGE_RED,
	CreepSize.enm.CHALLENGE_MASS: Color.GOLD,
	CreepSize.enm.CHALLENGE_BOSS: Color.GOLD,
}

# TODO: figure out actual values
const _item_chance_map: Dictionary = {
	CreepSize.enm.MASS: 0.05,
	CreepSize.enm.NORMAL: 0.10,
	CreepSize.enm.AIR: 0.10,
	CreepSize.enm.CHAMPION: 0.20,
	CreepSize.enm.BOSS: 0.50,
	CreepSize.enm.CHALLENGE_MASS: 0.10,
	CreepSize.enm.CHALLENGE_BOSS: 0.70,
}

# TODO: figure out actual values
const _item_quality_map: Dictionary = {
	CreepSize.enm.MASS: 0.0,
	CreepSize.enm.NORMAL: 0.0,
	CreepSize.enm.AIR: 0.0,
	CreepSize.enm.CHAMPION: 0.25,
	CreepSize.enm.BOSS: 0.25,
	CreepSize.enm.CHALLENGE_MASS: 0.25,
	CreepSize.enm.CHALLENGE_BOSS: 0.25,
}


func from_string(string: String) -> CreepSize.enm:
	return _string_map.find_key(string)


func convert_to_string(type: CreepSize.enm) -> String:
	return _string_map[type]


func get_color(type: CreepSize.enm) -> Color:
	return _color_map[type]


func get_default_item_chance(type: CreepSize.enm) -> float:
	return _item_chance_map[type]


func get_default_item_quality(type: CreepSize.enm) -> float:
	return _item_quality_map[type]
