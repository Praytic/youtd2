# Magic Hammer
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Magic Weapon[/color]\n"
	text += "Every 5th spell is a critical hit.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_casted(on_spell_cast)


func on_pickup():
	var itm: Item = self
	itm.user_int = 0


func on_spell_cast(_event: Event):
	var itm: Item = self

	itm.user_int = itm.user_int + 1

	if itm.user_int >= 5:
		itm.get_carrier().add_spell_crit()
		itm.user_int = 0
