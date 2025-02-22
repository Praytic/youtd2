extends ItemBehavior


# [ORIGINAL_GAME_DEVIATION] Removed auto-dropping behavior
# to make Strange Item usable during bonus waves.
# 
# In youtd1, Strange Item would automatically drop from
# towers during bonus waves. Note that in youtd1, bonus
# waves did not have individual wave numbers - they were all
# part of wave "241". So Strange Item would not work during
# bonus waves, even if it didn't get auto-removed from
# towers.
# 
# In youtd2, bonus waves have their own wave numbers so
# Strange Item can work during bonus waves.


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 5)


func on_create():
	item.user_int2 = 12
	item.user_int = item.user_int2
	item.set_charges(item.user_int)


func on_drop():
	var tower: Tower
	var cur_level: int = item.get_player().get_team().get_level()

	if cur_level > item.user_int3:
		item.user_int = item.user_int - (cur_level - item.user_int3)
		item.user_int3 = cur_level

		if item.user_int <= 0:
			CombatLog.log_item_ability(item, null, "Duplication")
			
			tower = item.get_carrier()
			var new: Item = Item.create(tower.get_player(), item.get_id(), tower.get_position_wc3())

			new.user_int2 = item.user_int2 + 6
			new.user_int = new.user_int2
			new.set_charges(new.user_int)
			item.user_int = item.user_int + item.user_int2

			new.fly_to_stash(0.0)

		item.set_charges(item.user_int)


func on_pickup():
	item.user_int3 = item.get_player().get_team().get_level()
	item.set_charges(item.user_int)


func periodic(_event: Event):
	var tower: Tower
	var cur_level: int = item.get_player().get_team().get_level()

	if cur_level > item.user_int3:
		item.user_int = item.user_int - (cur_level - item.user_int3)
		item.user_int3 = cur_level

		if item.user_int <= 0:
			tower = item.get_carrier()
			var new: Item = Item.create(tower.get_player(), item.get_id(), tower.get_position_wc3())

			new.user_int2 = item.user_int2 + 6
			new.user_int = new.user_int2
			new.set_charges(new.user_int)
			item.user_int = item.user_int + item.user_int2

			if !new.pickup(tower):
				new.fly_to_stash(0.0)

		item.set_charges(item.user_int)
