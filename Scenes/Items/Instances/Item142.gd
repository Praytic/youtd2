# Jah'Rakal's Fury
extends Item


var tomy_jahrakal_values: MultiboardValues


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Fervor[/color]\n"
	text += "Each subsequent attack on the same target increases the carrier's attackspeed by 2% up to a maximum of 100%. Whenever the carrier acquires a new target, the bonus is reduced by 50%. The bonus is bound to the item."
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-1% bonus reduction\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	tomy_jahrakal_values = MultiboardValues.new(1)
	tomy_jahrakal_values.set_key(0, "Attackspeed Increase")


func on_attack(event: Event):
	var itm: Item = self

	if itm.user_int == event.get_target().get_instance_id():
# 		100% attackspeed limit
		if itm.user_real != 1.00 && itm.user_real + 0.02 > 1.00:
#			Add the remaining bonus (99% -> 101%; limit -> 100%; add 100% - 99% = 1%)
			itm.get_carrier().modify_property(Modification.Type.MOD_ATTACKSPEED, 1.00 - itm.user_real)
			itm.user_real = 1.00
		else:
#			Add bonus
			itm.get_carrier().modify_property(Modification.Type.MOD_ATTACKSPEED, 0.02)
			itm.user_real = itm.user_real + 0.02
	else:
#		Save current target
		itm.user_int = event.get_target().get_instance_id()
#		Temp variable to store the current bonus
		itm.user_real2 = itm.user_real
#		Calculate the new bonus (Current bonus * (50% + towerlevel%))
		itm.user_real = itm.user_real * (50.0 + itm.get_carrier().get_level()) / 100
#		Change the bonus (new Bonus - current Bonus)
		itm.get_carrier().modify_property(Modification.Type.MOD_ATTACKSPEED, itm.user_real - itm.user_real2)


func on_create():
	var itm: Item = self
	itm.user_real = 0.00
	itm.user_int = 0


func on_drop():
	var itm: Item = self

# 	Remove bonus
	itm.get_carrier().modify_property(Modification.Type.MOD_ATTACKSPEED, -itm.user_real)


func on_pickup():
	var itm: Item = self

#	Add bonus
	itm.get_carrier().modify_property(Modification.Type.MOD_ATTACKSPEED, itm.user_real)


func on_tower_details() -> MultiboardValues:
	var itm: Item = self

#	No decimal places
	tomy_jahrakal_values.set_value(0, str(int(itm.user_real * 100)) + "%")

	return tomy_jahrakal_values
