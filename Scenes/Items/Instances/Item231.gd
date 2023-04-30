# Currency Converter
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Exchange[/color]\n"
	text += "Every 15 seconds the wielder converts a flat 2 experience into 7 gold.\n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-0.3 seconds cooldown."

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(self, "_on_periodic", 1.0)


func _on_periodic(event: Event):
	var itm = self

	var tower: Tower = itm.get_carrier()
	var lvl: int = tower.get_level()
	event.enable_advanced(15 - lvl * 0.3, false)
	if tower.get_exp() >= 2.0:
		Utils.sfx_on_unit("UI\\Feedback\\GoldCredit\\GoldCredit.mdl", tower, "head")
		tower.remove_exp_flat(2)
		tower.getOwner().give_gold(7, tower, true, true)
	else:
		tower.getOwner().display_floating_text("Not enough credits!", tower, 255, 0, 0)
