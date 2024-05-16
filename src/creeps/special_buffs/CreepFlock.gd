class_name CreepFlock extends BuffType


func _init(parent: Node):
	super("creep_flock", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_BOUNTY_GRANTED, -0.50, 0.0)
	modifier.add_modification(Modification.Type.MOD_EXP_GRANTED, -0.50, 0.0)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_DEATH, -0.50, 0.0)
	set_buff_modifier(modifier)
