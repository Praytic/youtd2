class_name Element extends Node

enum enm {
	ICE ,
	NATURE,
	FIRE,
	ASTRAL,
	DARKNESS,
	IRON,
	STORM,
	NONE,
}


static var _string_map: Dictionary = {
	Element.enm.ICE: "ice",
	Element.enm.NATURE: "nature",
	Element.enm.FIRE: "fire",
	Element.enm.ASTRAL: "astral",
	Element.enm.DARKNESS: "darkness",
	Element.enm.IRON: "iron",
	Element.enm.STORM: "storm",
	Element.enm.NONE: "none",
}

static var _main_attack_types_map: Dictionary = {
	Element.enm.ICE: [AttackType.enm.ELEMENTAL, AttackType.enm.ENERGY],
	Element.enm.NATURE: [AttackType.enm.PHYSICAL, AttackType.enm.DECAY, AttackType.enm.ESSENCE],
	Element.enm.FIRE: [AttackType.enm.ELEMENTAL, AttackType.enm.DECAY],
	Element.enm.ASTRAL: [AttackType.enm.ENERGY, AttackType.enm.ELEMENTAL, AttackType.enm.ARCANE],
	Element.enm.DARKNESS: [AttackType.enm.DECAY, AttackType.enm.PHYSICAL],
	Element.enm.IRON: [AttackType.enm.PHYSICAL, AttackType.enm.DECAY],
	Element.enm.STORM: [AttackType.enm.ENERGY, AttackType.enm.PHYSICAL],
	Element.enm.NONE: [AttackType.enm.PHYSICAL, AttackType.enm.PHYSICAL],
}


static var _dmg_from_element_map: Dictionary = {
	Element.enm.ICE: Modification.Type.MOD_DMG_FROM_ICE,
	Element.enm.NATURE: Modification.Type.MOD_DMG_FROM_NATURE,
	Element.enm.FIRE: Modification.Type.MOD_DMG_FROM_FIRE,
	Element.enm.ASTRAL: Modification.Type.MOD_DMG_FROM_ASTRAL,
	Element.enm.DARKNESS: Modification.Type.MOD_DMG_FROM_DARKNESS,
	Element.enm.IRON: Modification.Type.MOD_DMG_FROM_IRON,
	Element.enm.STORM: Modification.Type.MOD_DMG_FROM_STORM,
	Element.enm.NONE: Modification.Type.MOD_DMG_FROM_ICE,
}

static var _color_map: Dictionary = {
	Element.enm.ICE: Color.CORNFLOWER_BLUE,
	Element.enm.NATURE: Color.LIME_GREEN,
	Element.enm.FIRE: Color.ORANGE_RED,
	Element.enm.ASTRAL: Color.MEDIUM_AQUAMARINE,
	Element.enm.DARKNESS: Color.MEDIUM_PURPLE,
	Element.enm.IRON: Color.TAN,
	Element.enm.STORM: Color.LIGHT_YELLOW,
	Element.enm.NONE: Color.WHITE,
}


static func is_valid_string(string: String) -> bool:
	var key = _string_map.find_key(string)
	var is_valid: bool = key != null

	return is_valid


static func from_string(string: String) -> Element.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return Element.enm.ICE


static func convert_to_string(element: Element.enm) -> String:
	return _string_map[element]


static func get_display_string(element: Element.enm) -> String:
	var string: String
	match element:
		Element.enm.ICE: string = Utils.tr("ELEMENT_ICE")
		Element.enm.NATURE: string = Utils.tr("ELEMENT_NATURE")
		Element.enm.FIRE: string = Utils.tr("ELEMENT_FIRE")
		Element.enm.ASTRAL: string = Utils.tr("ELEMENT_ASTRAL")
		Element.enm.DARKNESS: string = Utils.tr("ELEMENT_DARKNESS")
		Element.enm.IRON: string = Utils.tr("ELEMENT_IRON")
		Element.enm.STORM: string = Utils.tr("ELEMENT_STORM")
		Element.enm.NONE: string = "none"

	return string


static func convert_to_dmg_from_element_mod(element: Element.enm) -> Modification.Type:
	return _dmg_from_element_map[element]


static func convert_to_colored_string(type: Element.enm) -> String:
	var string: String = get_display_string(type)
	var color: Color = get_color(type)
	var out: String = Utils.get_colored_string(string, color)

	return out


static func get_list() -> Array[Element.enm]:
	return [
		Element.enm.ICE,
		Element.enm.NATURE,
		Element.enm.FIRE,
		Element.enm.ASTRAL,
		Element.enm.DARKNESS,
		Element.enm.IRON,
		Element.enm.STORM,
	]


static func get_color(element: Element.enm) -> Color:
	var color: Color = _color_map[element]

	return color


static func get_flavor_text(element: Element.enm) -> String:
	var string: String
	match element:
		Element.enm.ICE: string = Utils.tr("ELEMENT_FLAVOR_TEXT_ICE")
		Element.enm.NATURE: string = Utils.tr("ELEMENT_FLAVOR_TEXT_NATURE")
		Element.enm.FIRE: string = Utils.tr("ELEMENT_FLAVOR_TEXT_FIRE")
		Element.enm.ASTRAL: string = Utils.tr("ELEMENT_FLAVOR_TEXT_ASTRAL")
		Element.enm.DARKNESS: string = Utils.tr("ELEMENT_FLAVOR_TEXT_DARKNESS")
		Element.enm.IRON: string = Utils.tr("ELEMENT_FLAVOR_TEXT_IRON")
		Element.enm.STORM: string = Utils.tr("ELEMENT_FLAVOR_TEXT_STORM")
		Element.enm.NONE: string = "none"

	return string


static func get_main_attack_types(element: Element.enm) -> String:
	var attack_enum_list: Array = _main_attack_types_map[element]
	var attack_string_list: Array[String] = []

	for attack_enum in attack_enum_list:
		var attack_string: String = AttackType.convert_to_colored_string(attack_enum)
		attack_string_list.append(attack_string)

	var combined_string: String = ", ".join(attack_string_list)

	return combined_string
