class_name ArmorType

enum enm {
	HEL,
	MYT,
	LUA,
	SOL,
	SIF,
}

static func convert_to_string(type: ArmorType.enm) -> String:
	match type:
		ArmorType.enm.HEL: return "Hel"
		ArmorType.enm.MYT: return "Myt"
		ArmorType.enm.LUA: return "Lua"
		ArmorType.enm.SOL: return "Sol"
		ArmorType.enm.SIF: return "Sif"

	return "[unknown armor type]"
