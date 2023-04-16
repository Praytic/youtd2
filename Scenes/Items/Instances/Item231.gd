# Currency Converter
extends Item


func get_extra_tooltip_text() -> String:
	return "[color=gold]Exchange[/color]\nEvery 15 seconds the wielder converts a flat 2 experience into 7 gold.\n[color=orange]Level Bonus:[/color]\n-0.3 seconds cooldown."

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
		tower.earn_gold.emit(7, true, true)
	else:
		Utils.display_floating_text("Not enough credits!", tower, 255, 0, 0)
