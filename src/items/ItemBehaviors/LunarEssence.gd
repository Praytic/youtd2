extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Sacred Wisdom[/color]\n"
	text += "Grants 200 flat experience to the holder. The experience is bound to the item and lost on drop. If the tower has less than 200 experience when the item is dropped, the item will drain experience from the next tower it is placed in, up to 200 experience.\n"

	return text


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
