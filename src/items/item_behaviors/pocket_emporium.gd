extends ItemBehavior


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 10)


func on_autocast(_event: Event):
	var i: int = item.get_charges()
	var tower: Tower = item.get_carrier()
	var p: Player = item.get_player()
	var new: Item
	var rnd: float = Globals.synced_rng.randi_range(0, 24)
	var rarity: int = 1

	if rnd < 2:
		rarity = 3
	elif rnd < 6:
		rarity = 2

	if i > 0 && item.get_player().get_gold() >= 500:
		var random_item: int = ItemDropCalc.get_random_item_at_rarity_bounded(rarity, 14, 25)
		
		if random_item != 0:
			item.user_int2 = item.user_int2 - 1
			p.give_gold(-500, tower, false, true)
			new = Item.create(tower.get_player(), random_item, tower.get_position_wc3())
			new.fly_to_stash(0.0)

	check_level()


func check_level():
	var cur_level: int = item.get_player().get_team().get_level()

	if cur_level > item.user_int3:
		item.user_int = item.user_int + (cur_level - item.user_int3)
		item.user_int3 = cur_level

	while true:
		if item.user_int < 5 || item.user_int2 >= 5:
			break

		item.user_int = item.user_int - 5
		item.user_int2 = item.user_int2 + 1

	item.set_charges(item.user_int2)


func on_create():
	item.set_charges(1)
	item.user_int = 0
	item.user_int2 = 1
	item.user_int3 = item.get_player().get_team().get_level()
	check_level()


func on_drop():
	check_level()


func on_pickup():
	check_level()


func periodic(_event: Event):
	check_level()
