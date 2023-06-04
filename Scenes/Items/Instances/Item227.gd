# Lunar Essence
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Sacred Wisdom[/color]\n"
	text += "Grants 200 flat experience to the holder. The experience is bound to the item and lost on drop. If the tower has less than 200 experience when the item is dropped, the item will drain experience from the next tower it is placed in, up to 200 experience.\n"

	return text


func on_create():
	var itm: Item = self
	itm.user_real = 200


func on_drop():
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	itm.user_real = tower.remove_exp_flat(200)


func on_pickup():
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var r: float = itm.user_real
	if r > 0:
		tower.add_exp_flat(r)
