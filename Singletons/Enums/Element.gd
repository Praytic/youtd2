extends Node

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


const _string_map: Dictionary = {
	Element.enm.ICE: "ice",
	Element.enm.NATURE: "nature",
	Element.enm.FIRE: "fire",
	Element.enm.ASTRAL: "astral",
	Element.enm.DARKNESS: "darkness",
	Element.enm.IRON: "iron",
	Element.enm.STORM: "storm",
	Element.enm.NONE: "none",
}

const _flavor_text_map: Dictionary = {
	Element.enm.ICE: "The element of frost magic. Ice towers use slowing and drowning effects on enemies.",
	Element.enm.NATURE: "The element of life. Nature towers focus on supportive effects to enhance other towers. Strong against orc enemies.",
	Element.enm.FIRE: "The element of destruction. Fire towers focus on dealing high damage and splash damage. Strong against humand and mass enemies.",
	Element.enm.ASTRAL: "The good element. Astral towers use special astral related abilities to buff other towers. Strong against undead enemies.",
	Element.enm.DARKNESS: "The evil element. Darkness towers specialize in curses, necromancy and debuffs which weaken enemies. Strong against nature enemies.",
	Element.enm.IRON: "The manmade element. Iron towers are balanced all around fighters. Strong against boss enemies.",
	Element.enm.STORM: "The weather element. Storm towers use lightning and other weather phenomena to deal damage to enemies. Strong against air and magical enemies.",
	Element.enm.NONE: "none",
}

const _main_attack_types_map: Dictionary = {
	Element.enm.ICE: [AttackType.enm.ELEMENTAL, AttackType.enm.ENERGY],
	Element.enm.NATURE: [AttackType.enm.PHYSICAL, AttackType.enm.DECAY, AttackType.enm.ESSENCE],
	Element.enm.FIRE: [AttackType.enm.ELEMENTAL, AttackType.enm.DECAY],
	Element.enm.ASTRAL: [AttackType.enm.ENERGY, AttackType.enm.ELEMENTAL, AttackType.enm.MAGIC],
	Element.enm.DARKNESS: [AttackType.enm.DECAY, AttackType.enm.PHYSICAL],
	Element.enm.IRON: [AttackType.enm.PHYSICAL, AttackType.enm.DECAY],
	Element.enm.STORM: [AttackType.enm.ENERGY, AttackType.enm.PHYSICAL],
	Element.enm.NONE: [AttackType.enm.PHYSICAL, AttackType.enm.PHYSICAL],
}


const _dmg_from_element_map: Dictionary = {
	Element.enm.ICE: Modification.Type.MOD_DMG_FROM_ICE,
	Element.enm.NATURE: Modification.Type.MOD_DMG_FROM_NATURE,
	Element.enm.FIRE: Modification.Type.MOD_DMG_FROM_FIRE,
	Element.enm.ASTRAL: Modification.Type.MOD_DMG_FROM_ASTRAL,
	Element.enm.DARKNESS: Modification.Type.MOD_DMG_FROM_DARKNESS,
	Element.enm.IRON: Modification.Type.MOD_DMG_FROM_IRON,
	Element.enm.STORM: Modification.Type.MOD_DMG_FROM_STORM,
	Element.enm.NONE: Modification.Type.MOD_DMG_FROM_ICE,
}

const _color_map: Dictionary = {
	Element.enm.ICE: Color.CORNFLOWER_BLUE,
	Element.enm.NATURE: Color.LIME_GREEN,
	Element.enm.FIRE: Color.ORANGE_RED,
	Element.enm.ASTRAL: Color.MEDIUM_AQUAMARINE,
	Element.enm.DARKNESS: Color.DARK_VIOLET,
	Element.enm.IRON: Color.TAN,
	Element.enm.STORM: Color.LIGHT_YELLOW,
	Element.enm.NONE: Color.WHITE,
}


func from_string(string: String) -> Element.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return Element.enm.ICE


func convert_to_string(element: Element.enm) -> String:
	return _string_map[element]


func convert_to_dmg_from_element_mod(element: Element.enm) -> Modification.Type:
	return _dmg_from_element_map[element]


func convert_to_colored_string(type: Element.enm) -> String:
	var string: String = convert_to_string(type).capitalize()
	var color: Color = get_color(type)
	var out: String = Utils.get_colored_string(string, color)

	return out


func get_list() -> Array[Element.enm]:
	return [
		Element.enm.ICE,
		Element.enm.NATURE,
		Element.enm.FIRE,
		Element.enm.ASTRAL,
		Element.enm.DARKNESS,
		Element.enm.IRON,
		Element.enm.STORM,
	]


func get_color(element: Element.enm) -> Color:
	var color: Color = _color_map[element]

	return color


func get_flavor_text(element: Element.enm) -> String:
	var flavor_text: String = _flavor_text_map[element]

	return flavor_text


func get_main_attack_types(element: Element.enm) -> String:
	var attack_enum_list: Array = _main_attack_types_map[element]
	var attack_string_list: Array[String] = []

	for attack_enum in attack_enum_list:
		var attack_string: String = AttackType.convert_to_colored_string(attack_enum)
		attack_string_list.append(attack_string)

	var combined_string: String = ", ".join(attack_string_list)

	return combined_string
