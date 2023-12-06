# Wanted List
extends Item


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Headhunt[/color]\n"
	text += "Gives 2 additional gold for every creep the carrier kills.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func on_kill(_event: Event):
	var itm: Item = self

	var tower: Tower = itm.get_carrier()
	CombatLog.log_item_ability(self, null, "Headhunt")
	itm.get_carrier().get_player().give_gold(2, tower, true, true)
