extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {mana_add = 0.5},
		2: {mana_add = 0.6},
		3: {mana_add = 0.7},
		4: {mana_add = 0.8},
		5: {mana_add = 0.9},
	}


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Overheat[/color]\n"
	text += "Each attack costs 1 mana, which is regenerated at a rate of 1 mana per second.\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Overheat[/color]\n"
	text += "Attacks cost mana.\n"

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, _stats.mana_add)


func on_attack(_event: Event):
	var tower: Tower = self

	var mana: float = tower.get_mana()

	if mana < 1:
		tower.order_stop()
	else:
		tower.set_mana(mana - 1)
