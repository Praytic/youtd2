# Jewels of the Moon
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Celestial Wisdom[/color]\n"
	text += "Grants the wielder 2 experience every 15 seconds. The amount of experience is increased by 2 at night.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 15)


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.20, 0.0)


func periodic(_event: Event):
	var itm: Item = self
	var night: float = Utils.get_time_of_day()
	var target_effect: int
	var tower: Unit = itm.get_carrier()

	target_effect = Effect.create_scaled("DispelMagicTarget.mdl", tower.get_visual_position().x, tower.get_visual_position().y, 0, 0, 0.8)
	Effect.set_lifetime(target_effect, 2.0)

	if night >= 18.00 || night < 6.00:
		tower.add_exp(4.0)
	else:
		tower.add_exp(2.0)
