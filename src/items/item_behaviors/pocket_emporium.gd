extends ItemBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed bug where this item would
# accumulate hidden charges above 5. Bug happened because
# the charge count was capped to 5 but the "accumulator"
# variable was uncapped and would accumulate and then get
# converted to real charges when item was used.


var wave_accumulator: int = 0
var charge_counter: int = 0
var last_accumulated_level: int = 0


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
			charge_counter -= 1
			p.give_gold(-500, tower, false, true)
			new = Item.create(tower.get_player(), random_item, tower.get_position_wc3())
			new.fly_to_stash(0.0)

	check_level()


func check_level():
	var cur_level: int = item.get_player().get_team().get_level()

	if cur_level > last_accumulated_level:
		wave_accumulator = wave_accumulator + (cur_level - last_accumulated_level)

#		NOTE: need to set accumulator to 0 here because if
#		charge count is at 5, then it's capped out and we
#		need to stop accumulating charges from waves.
		if charge_counter == 5:
			wave_accumulator = 0

		last_accumulated_level = cur_level

	while true:
		if wave_accumulator < 5 || charge_counter >= 5:
			break

		wave_accumulator = wave_accumulator - 5
		charge_counter += 1

	item.set_charges(charge_counter)


func on_create():
	item.set_charges(1)
	wave_accumulator = 0
	charge_counter = 1
	last_accumulated_level = item.get_player().get_team().get_level()
	check_level()


func on_drop():
	check_level()


func on_pickup():
	check_level()


func periodic(_event: Event):
	check_level()
