class_name CreepGreaterSpeed extends BuffType


func _init(parent: Node):
	super("creep_greater_speed", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_MOVESPEED, 0.6, 0.0)
	modifier.add_modification(Modification.Type.MOD_HP_PERC, -0.33, 0.0)
	set_buff_modifier(modifier)
	set_buff_tooltip("Greater Speed\nThese creeps have 60% increased movement speed.")
