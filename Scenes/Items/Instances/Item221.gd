# Eye of True Sight
extends Item


var eye_of_true_sight: BuffType


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
	eye_of_true_sight = MagicalSightBuff.new("eye_of_true_sight", 900, self)
	eye_of_true_sight.set_buff_tooltip("Eye of True Sight\nThis unit has Eye of True Sight; it will reveal invisible units in range.")


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var itm: Item = self

	if event.get_target().is_invisible():
		event.damage = event.damage * (1.2 + 0.008 * itm.get_carrier().get_level())


func on_pickup():
	var itm: Item = self
	var carrier: Unit = itm.get_carrier()
	eye_of_true_sight.apply_to_unit_permanent(carrier, carrier, 0)	
