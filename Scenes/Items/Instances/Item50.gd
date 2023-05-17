# Magic Hammer
extends Item


# TODO: Unit.add_spell_crit() is not implemented so this
# item has no effect.


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Magic Weapon[/color]\n"
	text += "Magic Weapon"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_casted(on_spell_cast)


func on_item_pickup():
	var itm: Item = self
	itm.user_int = 0


func on_spell_cast(_event: Event):
	var itm: Item = self

	itm.user_int = itm.user_int + 1

	if itm.user_int >= 5:
		itm.get_carrier().add_spell_crit()
		itm.user_int = 0
