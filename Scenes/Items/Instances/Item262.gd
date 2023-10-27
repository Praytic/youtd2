# Granite Hammer
extends Item


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Heavy Weapon[/color]\n"
	text += "Every 5th attack is a critical hit.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_attack(_event: Event):
	var itm: Item = self

	var tower: Tower = itm.get_carrier()
	itm.user_int = itm.user_int + 1

	if itm.user_int == 5:
		tower.add_attack_crit()

		itm.user_int = 0


func on_pickup():
	var itm: Item = self
	itm.user_int = 1
