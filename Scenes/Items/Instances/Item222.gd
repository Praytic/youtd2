# Book of Knowledge
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]High Knowledge[/color]\n"
	text += "The carrier gains 0.2 experience every time its attack hits its main target. The amount of experience gained is range and base attackspeed adjusted.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage, 1.0, 0.0)


func on_damage(event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	var cd: float = tower.get_base_attack_speed()
	var range: float = tower.get_range()

	if event.is_main_target():
		tower.add_exp(0.2 * cd * (800 / range))
