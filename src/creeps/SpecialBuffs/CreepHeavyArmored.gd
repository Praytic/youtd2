class_name CreepHeavyArmored extends BuffType


func _init(parent: Node):
	super("creep_heavy_armored", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_ARMOR, 25, 0.0)
	modifier.add_modification(Modification.Type.MOD_ARMOR_PERC, 1.0, 0.0)
	set_buff_modifier(modifier)
