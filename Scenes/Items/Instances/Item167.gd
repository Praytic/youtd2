# Never-ending Keg
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Drunk![/color]\n"
	text += "On each attack this tower has a 10% chance to miss.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.65, 0.0)
	modifier.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)


func on_damage(event: Event):
	var itm: Item = self

	if Utils.rand_chance(0.10):
		itm.get_carrier().get_player().display_small_floating_text("Miss", itm.get_carrier(), 255, 0, 0, 40.0)
		event.damage = 0
