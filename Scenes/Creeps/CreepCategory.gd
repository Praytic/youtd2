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
