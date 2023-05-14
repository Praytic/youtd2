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


func from_string(string: String) -> Element.enm:
	return _string_map.find_key(string)


func convert_to_string(element: Element.enm) -> String:
	return _string_map[element]


func convert_to_dmg_from_element_mod(element: Element.enm) -> Modification.Type:
	return _dmg_from_element_map[element]
