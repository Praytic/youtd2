# Fist of Doom
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Pay With Blood[/color]\n"
	text += "Every 10 seconds the user of this item loses 2 experience.\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.40, 0.0)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.40, 0.0)


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 10)


func periodic(_event: Event):
	var itm: Item = self
	itm.get_carrier().remove_exp(2)
