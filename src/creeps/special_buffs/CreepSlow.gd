class_name CreepSlow extends BuffType


func _init(parent: Node):
	super("creep_slow", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_MOVESPEED, -0.33, 0.0)
	set_buff_modifier(modifier)
