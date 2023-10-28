extends Node

enum enm {
	UNDEAD,
	MAGIC,
	NATURE,
	ORC,
	HUMANOID,
	CHALLENGE,
}


const _string_map: Dictionary = {
	CreepCategory.enm.UNDEAD: "undead",
	CreepCategory.enm.MAGIC: "magic",
	CreepCategory.enm.NATURE: "nature",
	CreepCategory.enm.ORC: "orc",
	CreepCategory.enm.HUMANOID: "humanoid",
	CreepCategory.enm.CHALLENGE: "challenge",
}

const _color_map: Dictionary = {
	CreepCategory.enm.UNDEAD: Color.MEDIUM_PURPLE,
	CreepCategory.enm.MAGIC: Color.CORNFLOWER_BLUE,
	CreepCategory.enm.NATURE: Color.LIME_GREEN,
	CreepCategory.enm.ORC: Color.DARK_SEA_GREEN,
	CreepCategory.enm.HUMANOID: Color.TAN,
	CreepCategory.enm.CHALLENGE: Color.GRAY,
}


func from_string(string: String) -> CreepCategory.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return CreepCategory.enm.UNDEAD


func convert_to_string(type: CreepCategory.enm) -> String:
	return _string_map[type]


func get_color(type: CreepCategory.enm) -> Color:
	var color: Color = _color_map[type]

	return color


func convert_to_colored_string(type: CreepCategory.enm) -> String:
	var string: String = convert_to_string(type).capitalize()
	var color: Color = _color_map[type]
	var out: String = Utils.get_colored_string(string, color)

	return out


func convert_to_mod_dmg_type(category: CreepCategory.enm) -> Modification.Type:
	const creep_category_to_mod_map: Dictionary = {
		CreepCategory.enm.UNDEAD: Modification.Type.MOD_DMG_TO_MASS,
		CreepCategory.enm.MAGIC: Modification.Type.MOD_DMG_TO_MAGIC,
		CreepCategory.enm.NATURE: Modification.Type.MOD_DMG_TO_NATURE,
		CreepCategory.enm.ORC: Modification.Type.MOD_DMG_TO_ORC,
		CreepCategory.enm.HUMANOID: Modification.Type.MOD_DMG_TO_HUMANOID,
		CreepCategory.enm.CHALLENGE: Modification.Type.MOD_DMG_TO_CHALLENGE,
	}

	var mod_type: Modification.Type = creep_category_to_mod_map[category]

	return mod_type
