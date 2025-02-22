extends ItemBehavior


var multiboard: MultiboardValues


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Attack speed Increase")


func on_attack(event: Event):
	if item.user_int == event.get_target().get_instance_id():
# 		100% attack speed limit
		if item.user_real != 1.00 && item.user_real + 0.02 > 1.00:
#			Add the remaining bonus (99% -> 101%; limit -> 100%; add 100% - 99% = 1%)
			item.get_carrier().modify_property(Modification.Type.MOD_ATTACKSPEED, 1.00 - item.user_real)
			item.user_real = 1.00
		else:
#			Add bonus
			item.get_carrier().modify_property(Modification.Type.MOD_ATTACKSPEED, 0.02)
			item.user_real = item.user_real + 0.02
	else:
#		Save current target
		item.user_int = event.get_target().get_instance_id()
#		Temp variable to store the current bonus
		item.user_real2 = item.user_real
#		Calculate the new bonus (Current bonus * (50% + towerlevel%))
		item.user_real = item.user_real * (50.0 + item.get_carrier().get_level()) / 100
#		Change the bonus (new Bonus - current Bonus)
		item.get_carrier().modify_property(Modification.Type.MOD_ATTACKSPEED, item.user_real - item.user_real2)


func on_create():
	item.user_real = 0.00
	item.user_int = 0


func on_drop():
# 	Remove bonus
	item.get_carrier().modify_property(Modification.Type.MOD_ATTACKSPEED, -item.user_real)


func on_pickup():
#	Add bonus
	item.get_carrier().modify_property(Modification.Type.MOD_ATTACKSPEED, item.user_real)


func on_tower_details() -> MultiboardValues:
	var attack_speed_bonus_text: String = Utils.format_percent(item.user_real, 0)
	multiboard.set_value(0, attack_speed_bonus_text)

	return multiboard
