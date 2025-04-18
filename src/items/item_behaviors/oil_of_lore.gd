extends ItemBehavior


func on_pickup():
	var carrier: Tower = item.get_carrier()
	carrier.add_exp_flat(60)
