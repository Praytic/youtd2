extends ItemBehavior


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Magic Weapon[/color]\n"
	text += "Every 5th spell is a critical hit.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_casted(on_spell_cast)


func on_pickup():
	item.user_int = 0


func on_spell_cast(_event: Event):
	item.user_int = item.user_int + 1

	if item.user_int >= 5:
		CombatLog.log_item_ability(item, null, "Magic Weapon")
		item.get_carrier().add_spell_crit()
		item.user_int = 0
