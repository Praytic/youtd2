class_name CreepRich extends BuffType


func _init(parent: Node):
	super("creep_rich", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_BOUNTY_GRANTED, 0.60, 0.0)
	modifier.add_modification(Modification.Type.MOD_EXP_GRANTED, -1.0, 0.0)
	set_buff_modifier(modifier)
	set_buff_tooltip("Rich\nThese creeps grant 60% more bounty but no experience.")
