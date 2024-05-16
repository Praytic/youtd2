class_name CreepMechanical extends BuffType


func _init(parent: Node):
	super("creep_semi_mechanical", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.90, 0.0)
	set_buff_modifier(modifier)
