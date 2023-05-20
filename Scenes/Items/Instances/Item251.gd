# Arcane Script
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Script Reading[/color]\n"
	text += "Whenever the carrier casts its own active ability it gains [0.2 x cooldown] experience and grants [0.5 x cooldown] gold."

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_casted(on_spell_cast)


func on_spell_cast(event: Event):
	var itm: Item = self

	var cd: float = event.get_autocast_type().get_cooldown()

	if !event.get_autocast_type().is_item_autocast():
		itm.get_carrier().add_exp(0.2 * cd)
		itm.get_carrier().getOwner().give_gold(0.5 * cd, itm.get_carrier(), false, true)
