class_name CreepGravid extends BuffType


# TODO: implement the "children of these creeps jump out
# when their parents die."


func _init(parent: Node):
	super("creep_gravid", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_BOUNTY_GRANTED, -0.75, 0.0)
	modifier.add_modification(Modification.Type.MOD_EXP_GRANTED, -0.75, 0.0)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_DEATH, -0.75, 0.0)
	set_buff_modifier(modifier)

	add_event_on_death(on_death)



# TODO: spawn children here? 1 or many? How to implement
# their "maturing"?
func on_death(_event: Event):
	pass
