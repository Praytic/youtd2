extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {damage_bonus = 0.01},
		2: {damage_bonus = 0.02},
		3: {damage_bonus = 0.03},
		4: {damage_bonus = 0.04},
	}


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Magic Split[/color]\n"
	text += "This tower deals an additional amount of spell damage to its target equal to 100% of its attack damage. If the creep is immune this damage is dealt as energy damage equal to 80% of its attack damage not affected by level bonus.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% damage\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Magic Split[/color]\n"
	text += "On damage this tower deals 100% of its attack damage as spell damage to the target.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()

	if creep.is_immune():
		tower.do_attack_damage(creep, tower.get_current_attack_damage_with_bonus() * 0.8, tower.calc_attack_multicrit(0, 0, 0))
	else:
		tower.do_spell_damage(creep, tower.get_current_attack_damage_with_bonus() * (1 + _stats.damage_bonus * tower.get_level()), tower.calc_spell_crit_no_bonus())
