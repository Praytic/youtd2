extends Node

enum enm {
	PHYSICAL,
	DECAY,
	ENERGY,
	ESSENCE,
	ELEMENTAL,
}


const _string_map: Dictionary = {
	AttackType.enm.PHYSICAL: "physical",
	AttackType.enm.DECAY: "decay",
	AttackType.enm.ENERGY: "energy",
	AttackType.enm.ESSENCE: "essence",
	AttackType.enm.ELEMENTAL: "elemental",
}


const _damage_to_armor_map: Dictionary = {
	AttackType.enm.PHYSICAL: {
		ArmorType.enm.LUA: 1.8,
		ArmorType.enm.SOL: 1.2,
		ArmorType.enm.HEL: 0.9,
		ArmorType.enm.MYT: 0.6,
		ArmorType.enm.SIF: 0.4,
	},
	AttackType.enm.DECAY: {
		ArmorType.enm.SOL: 1.8,
		ArmorType.enm.HEL: 1.2,
		ArmorType.enm.MYT: 0.9,
		ArmorType.enm.LUA: 0.6,
		ArmorType.enm.SIF: 0.4,
	},
	AttackType.enm.ENERGY: {
		ArmorType.enm.HEL: 1.8,
		ArmorType.enm.MYT: 1.2,
		ArmorType.enm.LUA: 0.9,
		ArmorType.enm.SOL: 0.6,
		ArmorType.enm.SIF: 0.4,
	},
	AttackType.enm.ESSENCE: {
		ArmorType.enm.HEL: 1.0,
		ArmorType.enm.MYT: 1.0,
		ArmorType.enm.LUA: 1.0,
		ArmorType.enm.SOL: 1.0,
		ArmorType.enm.SIF: 1.0,
	},
	AttackType.enm.ELEMENTAL: {
		ArmorType.enm.MYT: 1.8,
		ArmorType.enm.LUA: 1.2,
		ArmorType.enm.SOL: 0.9,
		ArmorType.enm.HEL: 0.6,
		ArmorType.enm.SIF: 0.4,
	},
}


func from_string(string: String) -> AttackType.enm:
	return _string_map.find_key(string)


func get_damage_against(attack_type: AttackType.enm, armor_type: ArmorType.enm) -> float:
	var damage: float = _damage_to_armor_map[attack_type][armor_type]

	return damage
