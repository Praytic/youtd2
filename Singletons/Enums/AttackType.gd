extends Node

enum enm {
	PHYSICAL,
	DECAY,
	ENERGY,
	ESSENCE,
	ELEMENTAL,
	MAGIC,
}

var _list: Array[AttackType.enm] = [
	AttackType.enm.PHYSICAL,
	AttackType.enm.DECAY,
	AttackType.enm.ENERGY,
	AttackType.enm.ESSENCE,
	AttackType.enm.ELEMENTAL,
	AttackType.enm.MAGIC,
]

const _string_map: Dictionary = {
	AttackType.enm.PHYSICAL: "physical",
	AttackType.enm.DECAY: "decay",
	AttackType.enm.ENERGY: "energy",
	AttackType.enm.ESSENCE: "essence",
	AttackType.enm.ELEMENTAL: "elemental",
	AttackType.enm.MAGIC: "magic",
}

const _color_map: Dictionary = {
	AttackType.enm.PHYSICAL: Color.TAN,
	AttackType.enm.DECAY: Color.BLUE_VIOLET,
	AttackType.enm.ENERGY: Color.DODGER_BLUE,
	AttackType.enm.ESSENCE: Color.AQUAMARINE,
	AttackType.enm.ELEMENTAL: Color.CORNFLOWER_BLUE,
	AttackType.enm.MAGIC: Color.DEEP_SKY_BLUE,
}

const _no_damage_to_immune_map: Dictionary = {
	AttackType.enm.PHYSICAL: false,
	AttackType.enm.DECAY: false,
	AttackType.enm.ENERGY: false,
	AttackType.enm.ESSENCE: false,
	AttackType.enm.ELEMENTAL: false,
	AttackType.enm.MAGIC: true,
}

const _damage_to_armor_map: Dictionary = {
	AttackType.enm.PHYSICAL: {
		ArmorType.enm.LUA: 1.8,
		ArmorType.enm.SOL: 1.2,
		ArmorType.enm.HEL: 0.9,
		ArmorType.enm.MYT: 0.6,
		ArmorType.enm.SIF: 0.4,
		ArmorType.enm.ZOD: 1.0,
	},
	AttackType.enm.DECAY: {
		ArmorType.enm.SOL: 1.8,
		ArmorType.enm.HEL: 1.2,
		ArmorType.enm.MYT: 0.9,
		ArmorType.enm.LUA: 0.6,
		ArmorType.enm.SIF: 0.4,
		ArmorType.enm.ZOD: 1.0,
	},
	AttackType.enm.ENERGY: {
		ArmorType.enm.HEL: 1.8,
		ArmorType.enm.MYT: 1.2,
		ArmorType.enm.LUA: 0.9,
		ArmorType.enm.SOL: 0.6,
		ArmorType.enm.SIF: 0.4,
		ArmorType.enm.ZOD: 1.0,
	},
	AttackType.enm.ESSENCE: {
		ArmorType.enm.HEL: 1.0,
		ArmorType.enm.MYT: 1.0,
		ArmorType.enm.LUA: 1.0,
		ArmorType.enm.SOL: 1.0,
		ArmorType.enm.SIF: 1.0,
		ArmorType.enm.ZOD: 1.0,
	},
	AttackType.enm.ELEMENTAL: {
		ArmorType.enm.MYT: 1.8,
		ArmorType.enm.LUA: 1.2,
		ArmorType.enm.SOL: 0.9,
		ArmorType.enm.HEL: 0.6,
		ArmorType.enm.SIF: 0.4,
		ArmorType.enm.ZOD: 1.0,
	},
	AttackType.enm.MAGIC: {
		ArmorType.enm.MYT: 1.5,
		ArmorType.enm.LUA: 1.5,
		ArmorType.enm.SOL: 1.5,
		ArmorType.enm.HEL: 1.5,
		ArmorType.enm.SIF: 0.4,
		ArmorType.enm.ZOD: 1.0,
	},
}


func convert_to_string(type: AttackType.enm):
	return _string_map[type]


func from_string(string: String) -> AttackType.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid attack type string: \"%s\"" % string)

		return AttackType.enm.PHYSICAL


# NOTE: AttackType.PHYSICAL.getDamageAgainst() in JASS
func get_damage_against(attack_type: AttackType.enm, armor_type: ArmorType.enm) -> float:
	var damage: float = _damage_to_armor_map[attack_type][armor_type]

	return damage


func deals_no_damage_to_immune(attack_type: AttackType.enm) -> bool:
	return _no_damage_to_immune_map[attack_type]


func convert_to_colored_string(type: AttackType.enm) -> String:
	var string: String = convert_to_string(type).capitalize()
	var color: Color = _color_map[type]
	var out: String = Utils.get_colored_string(string, color)

	return out


func get_list() -> Array[AttackType.enm]:
	return _list.duplicate()


# Returns text which says how much damage this attack type
# deals against each armor type.
func get_text_for_damage_dealt(attack_type: AttackType.enm) -> String:
	var text: String = ""

	var armor_type_list: Array[ArmorType.enm] = ArmorType.get_list()

	for armor_type in armor_type_list:
		var armor_type_name: String = ArmorType.convert_to_string(armor_type).capitalize()
		var damage_dealt: float = AttackType.get_damage_against(attack_type, armor_type)
		var damage_dealt_string: String = Utils.format_percent(damage_dealt, 2)

		text += "%s:\t %s\n" % [armor_type_name, damage_dealt_string]

	return text
