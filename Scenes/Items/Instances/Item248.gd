# Pocket Emporium
extends Item


# TODO: need to implement AC_TYPE_NOAC_IMMEDIATE for this item to work

# TODO: implement RandomItemSet.permanent.get_random_item_at_rarity_bounded()

func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Purchase an Item[/color]\n"
	text += "Spend a charge to buy a random item for 500 gold. The item will be of level 14-25 and uncommon or higher rarity."
	text += " \n"
	text += "Gains a charge every 5th wave, up to a maximum of 5 charges. This ability is not affected by item quality.\n"
	text += " \n"
	text += "1s cooldown\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 10)


func on_autocast(event: Event):
	var itm: Item = self
	var i: int = itm.get_charges()
	var tower: Tower = itm.get_carrier()
	var p: Player = itm.getOwner()
	var new: Item
	var rnd: float = randi_range(0, 24)
	var rarity: int = 1

	if rnd < 2:
		rarity = 3
	elif rnd < 6:
		rarity = 2

	if i > 0 && Utils.get_player_state(p.get_the_player(), PlayerState.enm.RESOURCE_GOLD) >= 500:
		itm.user_int2 = itm.user_int2 - 1
		p.give_gold(-500, tower, false, true)
		# new = Item.create(p, RandomItemSet.permanent.get_random_item_at_rarity_bounded(rarity, 14, 25), tower.get_visual_position())
		new.fly_to_stash(0.0)

	check_level(itm)


func check_level(itm: Item):
	var cur_level: int = itm.getOwner().get_team().get_level()

	if cur_level > itm.user_int3:
		itm.user_int = itm.user_int + (cur_level - itm.user_int3)
		itm.user_int3 = cur_level

	while true:
		if itm.user_int < 5 || itm.user_int2 >= 5:
			break

		itm.user_int = itm.user_int - 5
		itm.user_int2 = itm.user_int2 + 1

	itm.set_charges(itm.user_int2)


func on_create():
	var itm: Item = self
	itm.set_charges(1)
	itm.user_int = 0
	itm.user_int2 = 1
	itm.user_int3 = itm.getOwner().get_team().get_level()
	check_level(itm)


func on_drop():
	var itm: Item = self
	check_level(itm)


func on_pickup():
	var itm: Item = self
	check_level(itm)


func periodic(event: Event):
	var itm: Item = self
	check_level(itm)
