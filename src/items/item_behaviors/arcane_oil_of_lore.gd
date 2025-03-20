extends ItemBehavior


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.7, 0)


func on_pickup():
	var carrier: Tower = item.get_carrier()
	carrier.add_exp_flat(120)
