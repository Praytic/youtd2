class_name CreepXtremeRegeneration extends BuffType


# TODO: figure out value for MOD_HP_REGEN


func _init(parent: Node):
	super("creep_xtreme_regeneration", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_HP_REGEN, 2, 0.0)
	set_buff_modifier(modifier)
