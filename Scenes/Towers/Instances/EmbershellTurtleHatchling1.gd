extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {mana_add = 0.5},
		2: {mana_add = 0.6},
		3: {mana_add = 0.7},
		4: {mana_add = 0.8},
		5: {mana_add = 0.9},
	}


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Overheat[/color]\n"
	text += "Each attack costs 1 mana, which is regenerated at a rate of 1 mana per second."

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_attack, 1.0, 0.0)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, _stats.mana_add)


func on_attack(_event: Event):
	var tower: Tower = self

	var tower_unit: Unit = tower as Unit
	var mana: float = Unit.get_unit_state(tower_unit, Unit.State.MANA)

	if mana < 1:
		tower.order_stop()
	else:
		Unit.set_unit_state(tower_unit, Unit.State.MANA, mana - 1)

	tower_unit = null
