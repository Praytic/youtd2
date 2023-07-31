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
	var color: Color = _color_map[type]
	var out: String = Utils.get_colored_string(string, color)

	return out
