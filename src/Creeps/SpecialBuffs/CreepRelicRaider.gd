class_name CreepRelicRaider extends BuffType


func _init(parent: Node):
	super("creep_relic_raider", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_BOUNTY_GRANTED, -0.50, 0.0)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_DEATH, 0.8, 0.0)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_DEATH, 0.3, 0.0)
	set_buff_modifier(modifier)
