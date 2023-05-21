# Strange Item
extends Item


# TODO: to implement this item, need to first implement the
# following f-ns:
# Item.create()
# Item.drop()
# Item.pickup()
# Item.fly_to_stash()
# Also, the way current stash system works is that it stores
# item id's. Need to change it to store item instances
# because this item sets "user_int" fields of instance
# before storing in stash.


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Duplication[/color]\n"
	text += "This item duplicates after being carried for 12 waves. The duplicate will be 6 waves slower to duplicate."

	return text


func on_create():
	var itm: Item = self
	itm.user_int2 = 12
	itm.user_int = itm.user_int2
	itm.set_charges(itm.user_int)
