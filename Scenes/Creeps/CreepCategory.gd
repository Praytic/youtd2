class_name CreepCategory

enum enm {
	UNDEAD,
	MAGIC,
	NATURE,
	ORC,
	HUMANOID,
}


static func convert_to_string(type: CreepCategory.enm) -> String:
	match type:
		CreepCategory.enm.UNDEAD: return "Undead"
		CreepCategory.enm.MAGIC: return "Magic"
		CreepCategory.enm.NATURE: return "Nature"
		CreepCategory.enm.ORC: return "Orc"
		CreepCategory.enm.HUMANOID: return "Humanoid"

	return "[unknown creep category]"


static func convert_to_colored_string(type: CreepCategory.enm) -> String:
	var string: String = convert_to_string(type)

	match type:
		CreepCategory.enm.UNDEAD: return "[color=VIOLET]%s[/color]" % string
		CreepCategory.enm.MAGIC: return "[color=BLUE]%s[/color]" % string
		CreepCategory.enm.NATURE: return "[color=AQUA]%s[/color]" % string
		CreepCategory.enm.ORC: return "[color=DARKGREEN]%s[/color]" % string
		CreepCategory.enm.HUMANOID: return "[color=TAN]%s[/color]" % string

	return "[unknown creep category]"
