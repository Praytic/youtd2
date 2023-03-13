class_name AttackType
extends Object

enum enm {
	PHYSICAL,
	DECAY,
	ENERGY,
	ESSENCE,
	ELEMENTAL,
}


static func from_string(string: String) -> AttackType.enm:
	match string:
		"physical": return AttackType.enm.PHYSICAL
		"decay": return AttackType.enm.DECAY
		"energy": return AttackType.enm.ENERGY
		"essence": return AttackType.enm.ESSENCE
		"elemental": return AttackType.enm.ELEMENTAL

	return AttackType.enm.PHYSICAL


# TODO: define actual values
static func get_damage_against(attack_type: AttackType.enm, armor_type: ArmorType.enm) -> float:
	var damage_map: Dictionary = {
		AttackType.enm.PHYSICAL: {
			ArmorType.enm.LIGHT: 1.0,
			ArmorType.enm.MEDIUM: 1.0,
			ArmorType.enm.HEAVY: 1.0,
		},
		AttackType.enm.DECAY: {
			ArmorType.enm.LIGHT: 1.0,
			ArmorType.enm.MEDIUM: 1.0,
			ArmorType.enm.HEAVY: 1.0,
		},
		AttackType.enm.ENERGY: {
			ArmorType.enm.LIGHT: 1.0,
			ArmorType.enm.MEDIUM: 1.0,
			ArmorType.enm.HEAVY: 1.0,
		},
		AttackType.enm.ESSENCE: {
			ArmorType.enm.LIGHT: 1.0,
			ArmorType.enm.MEDIUM: 1.0,
			ArmorType.enm.HEAVY: 1.0,
		},
		AttackType.enm.ELEMENTAL: {
			ArmorType.enm.LIGHT: 1.0,
			ArmorType.enm.MEDIUM: 1.0,
			ArmorType.enm.HEAVY: 1.0,
		},
	}
	var damage: float = damage_map[attack_type][armor_type]

	return damage
