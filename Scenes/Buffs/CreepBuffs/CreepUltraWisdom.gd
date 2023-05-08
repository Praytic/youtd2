class_name CreepUltraWisdom extends BuffType


func _init(parent: Node):
	super("creep_ultra_wisdom", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_BOUNTY_GRANTED, -1.0, 0.0)
	modifier.add_modification(Modification.Type.MOD_EXP_GRANTED, 2.0, 0.0)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_DEATH, -1.0, 0.0)
	set_buff_modifier(modifier)
