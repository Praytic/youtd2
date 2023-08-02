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
	CreepSize.enm.CHALLENGE_MASS: "challenge mass",
	CreepSize.enm.CHALLENGE_BOSS: "challenge boss",
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

const _experience_map: Dictionary = {
	CreepSize.enm.MASS: 1,
	CreepSize.enm.NORMAL: 2,
	CreepSize.enm.AIR: 4,
	CreepSize.enm.CHAMPION: 4,
	CreepSize.enm.BOSS: 20,
	CreepSize.enm.CHALLENGE_MASS: 2,
	CreepSize.enm.CHALLENGE_BOSS: 40,
}

const _portal_damage_multiplier_map: Dictionary = {
	CreepSize.enm.MASS: 1,
	CreepSize.enm.NORMAL: 2,
	CreepSize.enm.AIR: 4,
	CreepSize.enm.CHAMPION: 4,
	CreepSize.enm.BOSS: 20,
	CreepSize.enm.CHALLENGE_MASS: 0,
	CreepSize.enm.CHALLENGE_BOSS: 0,
}

const _gold_multiplier_map: Dictionary = {
	CreepSize.enm.MASS: 1,
	CreepSize.enm.NORMAL: 2,
	CreepSize.enm.AIR: 2,
	CreepSize.enm.CHAMPION: 4,
	CreepSize.enm.BOSS: 4,
	CreepSize.enm.CHALLENGE_MASS: 0,
	CreepSize.enm.CHALLENGE_BOSS: 0,
}

const health_multiplier_map: Dictionary = {
	CreepSize.enm.MASS: 0.3,
	CreepSize.enm.NORMAL: 1.0,
	CreepSize.enm.AIR: 1.0,
	CreepSize.enm.CHAMPION: 1.75,
	CreepSize.enm.BOSS: 6.0,
	CreepSize.enm.CHALLENGE_MASS: 1.6,
	CreepSize.enm.CHALLENGE_BOSS: 12.0,
}

func from_string(string: String) -> CreepSize.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return CreepSize.enm.MASS


func convert_to_string(type: CreepSize.enm) -> String:
	return _string_map[type]


func convert_to_colored_string(type: CreepSize.enm) -> String:
	var string: String = convert_to_string(type).capitalize()
	var color: Color = _color_map[type]
	var out: String = Utils.get_colored_string(string, color)

	return out


func get_default_item_chance(type: CreepSize.enm) -> float:
	return _item_chance_map[type]


func get_default_item_quality(type: CreepSize.enm) -> float:
	return _item_quality_map[type]


func get_experience(type: CreepSize.enm) -> float:
	return _experience_map[type]


func get_gold_multiplier(type: CreepSize.enm) -> float:
	return _gold_multiplier_map[type]


func get_portal_damage_multiplier(type: CreepSize.enm) -> float:
	return _portal_damage_multiplier_map[type]


func is_challenge(type: CreepSize.enm) -> bool:
	var out: bool = type == CreepSize.enm.CHALLENGE_MASS || type == CreepSize.enm.CHALLENGE_BOSS

	return out
