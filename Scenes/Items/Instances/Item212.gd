# Shining Rock
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Ethereal Knowledge[/color]\n"
	text += "Grants 100 flat experience to the holder. The experience is bound to the item and lost on drop. If the tower has less than 100 experience when the item is dropped, the item will drain experience from the next tower it is placed in, up to 100 experience.\n"

	return text


func on_create():
	var itm: Item = self
	itm.user_real = 100


func on_drop():
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	itm.user_real = tower.remove_exp_flat(100)


func on_pickup():
	var itm: Item = self
	var tower: Unit = itm.get_carrier()
	var r: float = itm.user_real
	if r > 0:
		tower.add_exp_flat(r)
