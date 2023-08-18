# Strange Item
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Duplication[/color]\n"
	text += "This item duplicates after being carried for 12 waves. The duplicate will be 6 waves slower to duplicate."

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 5)


func on_create():
	var itm: Item = self
	itm.user_int2 = 12
	itm.user_int = itm.user_int2
	itm.set_charges(itm.user_int)


func on_drop():
	var itm: Item = self
	var tower: Tower
	var cur_level: int = itm.get_player().get_team().get_level()

	if cur_level > itm.user_int3:
		itm.user_int = itm.user_int - (cur_level - itm.user_int3)
		itm.user_int3 = cur_level

		if itm.user_int <= 0:
			tower = itm.get_carrier()
			var new: Item = Item.create(tower.get_player(), itm.get_id(), tower.get_visual_position())

			new.user_int2 = itm.user_int2 + 6
			new.user_int = new.user_int2
			new.set_charges(new.user_int)
			itm.user_int = itm.user_int + itm.user_int2

			new.fly_to_stash(0.0)

		itm.ser_charges(itm.user_int)


func on_pickup():
	var itm: Item = self
	itm.user_int3 = itm.get_player().get_team().get_level()
	itm.set_charges(itm.user_int)


func periodic(_event: Event):
	var itm: Item = self

	var tower: Tower
	var cur_level: int = itm.get_player().get_team().get_level()

	if cur_level > itm.user_int3:
		itm.user_int = itm.user_int - (cur_level - itm.user_int3)
		itm.user_int3 = cur_level

		if itm.user_int <= 0:
			tower = itm.get_carrier()
			var new: Item = Item.create(tower.get_player(), itm.get_id(), tower.get_visual_position())

			new.user_int2 = itm.user_int2 + 6
			new.user_int = new.user_int2
			new.set_charges(new.user_int)
			itm.user_int = itm.user_int + itm.user_int2

			if !new.pickup(tower):
				new.fly_to_stash(0.0)

		itm.set_charges(itm.user_int)

	if cur_level > Utils.get_max_level():
		itm.drop()
		itm.fly_to_stash(0.0)
