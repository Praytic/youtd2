class_name CreepSize


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


static func from_string(string: String) -> CreepSize.enm:
	var string_upper: String = string.to_upper()
	var size: CreepSize.enm = CreepSize.enm.get(string_upper)

	return size


static func convert_to_string(type: CreepSize.enm) -> String:
	match type:
		CreepSize.enm.MASS: return "Mass"
		CreepSize.enm.NORMAL: return "Normal"
		CreepSize.enm.AIR: return "Air"
		CreepSize.enm.CHAMPION: return "Champion"
		CreepSize.enm.BOSS: return "Boss"
		CreepSize.enm.CHALLENGE_MASS: return "Challenge"
		CreepSize.enm.CHALLENGE_BOSS: return "Challenge"

	return "[unknown creep size]"
