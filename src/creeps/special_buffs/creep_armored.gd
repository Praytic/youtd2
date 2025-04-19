class_name CreepArmored extends BuffType


func _init(parent: Node):
	super("creep_armored", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(ModificationType.enm.MOD_ARMOR, 10, 0.0)
	modifier.add_modification(ModificationType.enm.MOD_ARMOR_PERC, 0.4, 0.0)
	set_buff_modifier(modifier)
