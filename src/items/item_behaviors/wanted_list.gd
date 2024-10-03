extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Headhunt[/color]\n"
	text += "Gives 2 additional gold for every creep the carrier kills.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func on_kill(_event: Event):
	var tower: Tower = item.get_carrier()
	CombatLog.log_item_ability(item, null, "Headhunt")
	item.get_carrier().get_player().give_gold(2, tower, true, true)
