class_name CreepXtremeSpeed extends BuffType


func _init(parent: Node):
	super("creep_extreme_speed", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_MOVESPEED, 10.0, 0.0)
	set_buff_modifier(modifier)
