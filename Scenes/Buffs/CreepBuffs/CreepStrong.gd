class_name CreepStrong extends BuffType


func _init(parent: Node):
	super("creep_strong", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_HP_PERC, 0.20, 0.0)
	modifier.add_modification(Modification.Type.MOD_EXP_GRANTED, 0.50, 0.0)
	modifier.add_modification(Modification.Type.MOD_BOUNTY_GRANTED, 0.25, 0.0)
	set_buff_modifier(modifier)
	set_buff_tooltip("Strong\nThese creeps have 20% more HP, but grant 50% more exp and 25% more bounty.")
