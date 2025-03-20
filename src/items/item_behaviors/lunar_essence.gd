extends ItemBehavior


func on_create():
	item.user_real = 200


func on_drop():
	var tower: Tower = item.get_carrier()
	item.user_real = tower.remove_exp_flat(200)


func on_pickup():
	var tower: Tower = item.get_carrier()
	var r: float = item.user_real
	if r > 0:
		tower.add_exp_flat(r)
