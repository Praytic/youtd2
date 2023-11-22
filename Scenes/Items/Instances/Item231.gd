# Currency Converter
extends Item


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Exchange[/color]\n"
	text += "Every 15 seconds the wielder converts a flat 2 experience into 7 gold.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-0.3 seconds cooldown.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(on_periodic, 1.0)


func on_periodic(event: Event):
	var itm = self

	var tower: Tower = itm.get_carrier()
	var lvl: int = tower.get_level()
	event.enable_advanced(15 - lvl * 0.3, false)
	if tower.get_exp() >= 2.0:
		SFX.sfx_on_unit("UI\\Feedback\\GoldCredit\\GoldCredit.mdl", tower, Unit.BodyPart.HEAD)
		tower.remove_exp_flat(2)
		tower.get_player().give_gold(7, tower, true, true)
	else:
		tower.get_player().display_floating_text("Not enough credits!", tower, 255, 0, 0)
