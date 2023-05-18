# Wanted List
extends Item


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Headhunt[/color]\n"
	text += "Gives 2 additional gold for every creep the carrier kills."

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func on_kill(event: Event):
	var itm: Item = self

	var tower: Tower = itm.get_carrier()
	itm.get_carrier().getOwner().give_gold(2, tower, true, true)
