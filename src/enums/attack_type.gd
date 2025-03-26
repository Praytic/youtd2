class_name AttackType extends Node


# NOTE: [ORIGINAL_GAME_DEVIATION] renamed "Magic"
# attack type from original game to "Arcane". Original
# "Magic" name for attack type was confusing because it
# sounded like it was related to "spell damage".

enum enm {
	PHYSICAL,
	DECAY,
	ENERGY,
	ESSENCE,
	ELEMENTAL,
	ARCANE,
}

static var _list: Array[AttackType.enm] = [
	AttackType.enm.PHYSICAL,
	AttackType.enm.DECAY,
	AttackType.enm.ENERGY,
	AttackType.enm.ESSENCE,
	AttackType.enm.ELEMENTAL,
	AttackType.enm.ARCANE,
]

static var _string_map: Dictionary = {
	AttackType.enm.PHYSICAL: "physical",
	AttackType.enm.DECAY: "decay",
	AttackType.enm.ENERGY: "energy",
	AttackType.enm.ESSENCE: "essence",
	AttackType.enm.ELEMENTAL: "elemental",
	AttackType.enm.ARCANE: "arcane",
}

static var _color_map: Dictionary = {
	AttackType.enm.PHYSICAL: Color.TAN,
	AttackType.enm.DECAY: Color.MEDIUM_PURPLE,
	AttackType.enm.ENERGY: Color.DODGER_BLUE,
	AttackType.enm.ESSENCE: Color.AQUAMARINE,
	AttackType.enm.ELEMENTAL: Color.CORNFLOWER_BLUE,
	AttackType.enm.ARCANE: Color.DEEP_SKY_BLUE,
}

static var _no_damage_to_immune_map: Dictionary = {
	AttackType.enm.PHYSICAL: false,
	AttackType.enm.DECAY: false,
	AttackType.enm.ENERGY: false,
	AttackType.enm.ESSENCE: false,
	AttackType.enm.ELEMENTAL: false,
	AttackType.enm.ARCANE: true,
}

static var _damage_to_armor_map: Dictionary = {
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
	AttackType.enm.ARCANE: {
		ArmorType.enm.MYT: 1.5,
		ArmorType.enm.LUA: 1.5,
		ArmorType.enm.SOL: 1.5,
		ArmorType.enm.HEL: 1.5,
		ArmorType.enm.SIF: 0.4,
		ArmorType.enm.ZOD: 1.0,
	},
}


static func convert_to_string(type: AttackType.enm):
	return _string_map[type]


static func from_string(string: String) -> AttackType.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid attack type string: \"%s\"" % string)

		return AttackType.enm.PHYSICAL


static func get_display_string(type: AttackType.enm) -> String:
	var string: String
	match type:
		AttackType.enm.PHYSICAL: string = Utils.tr("ATTACK_TYPE_PHYSICAL")
		AttackType.enm.DECAY: string = Utils.tr("ATTACK_TYPE_DECAY")
		AttackType.enm.ENERGY: string = Utils.tr("ATTACK_TYPE_ENERGY")
		AttackType.enm.ESSENCE: string = Utils.tr("ATTACK_TYPE_ESSENCE")
		AttackType.enm.ELEMENTAL: string = Utils.tr("ATTACK_TYPE_ELEMENTAL")
		AttackType.enm.ARCANE: string = Utils.tr("ATTACK_TYPE_ARCANE")
	
	return string


# NOTE: AttackType.PHYSICAL.getDamageAgainst() in JASS
static func get_damage_against(attack_type: AttackType.enm, armor_type: ArmorType.enm) -> float:
	var damage: float = _damage_to_armor_map[attack_type][armor_type]

	return damage


static func deals_no_damage_to_immune(attack_type: AttackType.enm) -> bool:
	return _no_damage_to_immune_map[attack_type]


# TODO: rename to "get_colored_display_string()"
static func convert_to_colored_string(type: AttackType.enm) -> String:
	var string: String = get_display_string(type)
	var color: Color = _color_map[type]
	var out: String = Utils.get_colored_string(string, color)

	return out


static func get_list() -> Array[AttackType.enm]:
	return _list.duplicate()


# Returns text which says how much damage this attack type
# deals against each armor type.
# NOTE: this is rich text
static func get_rich_text_for_damage_dealt(attack_type: AttackType.enm) -> String:
	var text: String = ""

	var armor_type_list: Array[ArmorType.enm] = ArmorType.get_list()

	for armor_type in armor_type_list:
		var armor_type_name: String = ArmorType.convert_to_colored_string(armor_type)
		var damage_dealt: float = AttackType.get_damage_against(attack_type, armor_type)
		var damage_dealt_string: String = Utils.format_percent(damage_dealt, 2)

		text += "%s:\t %s\n" % [armor_type_name, damage_dealt_string]

	if attack_type == AttackType.enm.ARCANE:
		text += "[color=RED]%s[/color]\n" % Utils.tr("ATTACK_TYPE_CANNOT_HIT_IMMUNE")

	text = RichTexts.add_color_to_numbers(text)

	return text
