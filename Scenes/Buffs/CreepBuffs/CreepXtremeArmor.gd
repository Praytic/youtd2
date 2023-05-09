class_name CreepXtremeArmor extends BuffType


func _init(parent: Node):
	super("creep_xtreme_armor", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_ARMOR, 100, 0.0)
	modifier.add_modification(Modification.Type.MOD_ARMOR_PERC, 4.0, 0.0)
	modifier.add_modification(Modification.Type.MOD_MOVESPEED, -0.25, 0.0)
	set_buff_modifier(modifier)
