class_name CreepArmored extends BuffType


func _init(parent: Node):
	super("creep_armored", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_ARMOR, 10, 0.0)
	modifier.add_modification(Modification.Type.MOD_ARMOR_PERC, 0.4, 0.0)
	set_buff_modifier(modifier)
	set_buff_tooltip("Armored\nThese creeps have increased armor.")
