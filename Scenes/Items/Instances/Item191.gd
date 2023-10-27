# Speed Demon's Reward
extends Item


var palandu_SpeedBoard: MultiboardValues


func get_ability_description() -> String:
	var text: String = ""

	text += "Any time the carrier manages to attack the next creep wave within 12 seconds of attacking the current one, it receives bonus exp and gold as a Speed Award. The gold award amount is equal to 12 minus the time interval between attacking the different creep waves. The exp award is half of the gold award.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	palandu_SpeedBoard = MultiboardValues.new(1)
	palandu_SpeedBoard.set_key(0, "Total Gold Awarded")


func on_attack(event: Event):
	var itm: Item = self

	var c: Creep = event.get_target()
	var creep_level: int = c.get_spawn_level()
	var reward_value: float
	var t: Unit

	if itm.user_int > 0 && itm.user_int < creep_level:
		reward_value = 12.0 - (Utils.get_game_time() - itm.user_int2) / 25

		if reward_value > 0:
			t = itm.get_carrier()
			t.get_player().give_gold(reward_value, t, true, true)
			t.add_exp(reward_value / 2)
			itm.user_real = itm.user_real + reward_value

	itm.user_int = max(itm.user_int, creep_level)
	itm.user_int2 = roundi(Utils.get_game_time())


func on_create():
	var itm: Item = self
	itm.user_int = -101
	itm.user_int2 = -101
	itm.user_real = 0


func on_tower_details() -> MultiboardValues:
	var itm: Item = self
	
	palandu_SpeedBoard.set_value(0, Utils.format_float(itm.user_real, 1))
	return palandu_SpeedBoard
