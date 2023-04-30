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


static func convert_to_colored_string(type: ArmorType.enm) -> String:
	var string: String = convert_to_string(type)

	match type:
		ArmorType.enm.HEL: return "[color=RED]%s[/color]" % string
		ArmorType.enm.MYT: return "[color=BLUE]%s[/color]" % string
		ArmorType.enm.LUA: return "[color=GREEN]%s[/color]" % string
		ArmorType.enm.SOL: return "[color=YELLOW]%s[/color]" % string
		ArmorType.enm.SIF: return "[color=PURPLE]%s[/color]" % string

	return "[unknown armor type]"
