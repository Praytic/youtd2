# Eye of True Sight
extends ItemBehavior


var true_sight_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Eye of True Sight[/color]\n"
	text += "Reveals invisible enemies in 900 range.\n"
	text += " \n"
	text += "[color=GOLD]True Sight[/color]\n"
	text += "The carrier of this item deals 20% more damage against invisible creeps.\n"
	text += " \n"
	text += "Level Bonus:\n"
	text += "+0.8% damage\n"

	return text


func item_init():
	true_sight_bt = MagicalSightBuff.new("true_sight_bt", 900, self)
	true_sight_bt.set_buff_tooltip("Eye of True Sight\nReveals invisible units in range.")


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	if event.get_target().is_invisible():
		event.damage = event.damage * (1.2 + 0.008 * item.get_carrier().get_level())


func on_pickup():
	var carrier: Unit = item.get_carrier()
	true_sight_bt.apply_to_unit_permanent(carrier, carrier, 0)	
