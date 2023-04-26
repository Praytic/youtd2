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


static func convert_to_colored_string(type: CreepSize.enm) -> String:
	var string: String = convert_to_string(type)

	match type:
		CreepSize.enm.MASS: return "[color=ORANGE]%s[/color]" % [string]
		CreepSize.enm.NORMAL: return "[color=GREEN]%s[/color]" % [string]
		CreepSize.enm.AIR: return "[color=BLUE]%s[/color]" % [string]
		CreepSize.enm.CHAMPION: return "[color=PURPLE]%s[/color]" % [string]
		CreepSize.enm.BOSS: return "[color=RED]%s[/color]" % [string]
		CreepSize.enm.CHALLENGE_MASS: return "[color=GOLD]%s[/color]" % [string]
		CreepSize.enm.CHALLENGE_BOSS: return "[color=GOLD]%s[/color]" % [string]

	return "[unknown creep size]"
