extends ItemBehavior


var multiboard: MultiboardValues


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(1, "Golden Trident")


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()
	var gold_bonus: float = 2.0

	if event.get_number_of_crits() > 0:
		gold_bonus = gold_bonus * event.get_number_of_crits() * tower.get_base_attack_speed() * tower.get_prop_bounty_received()

		tower.get_player().give_gold(int(gold_bonus), tower, true, true)


func on_create():
	item.user_real = 0.00


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, Utils.format_float(item.user_real, 1))

	return multiboard
