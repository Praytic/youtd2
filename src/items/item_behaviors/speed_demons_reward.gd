extends ItemBehavior


var multiboard: MultiboardValues


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	multiboard = MultiboardValues.new(1)
	var gold_awarded_label: String = tr("R9SJ")
	multiboard.set_key(0, gold_awarded_label)


func on_attack(event: Event):
	var c: Creep = event.get_target()
	var creep_level: int = c.get_spawn_level()
	var reward_value: float
	var t: Unit

	if item.user_int > 0 && item.user_int < creep_level:
		reward_value = 12.0 - (Utils.get_time() - item.user_int2)

		if reward_value > 0:
			CombatLog.log_item_ability(item, null, "Reward")
			t = item.get_carrier()
			t.get_player().give_gold(reward_value, t, true, true)
			t.add_exp(reward_value / 2)
			item.user_real = item.user_real + reward_value

	item.user_int = max(item.user_int, creep_level)
	item.user_int2 = roundi(Utils.get_time())


func on_create():
	item.user_int = -101
	item.user_int2 = -101
	item.user_real = 0


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, Utils.format_float(item.user_real, 1))
	return multiboard
