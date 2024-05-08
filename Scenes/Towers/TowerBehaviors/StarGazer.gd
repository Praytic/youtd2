extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {damage_bonus = 0.01},
		2: {damage_bonus = 0.02},
		3: {damage_bonus = 0.03},
		4: {damage_bonus = 0.04},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Magic Split"
	ability.icon = "res://Resources/Icons/magic/claw_01.tres"
	ability.description_short = "On damage this tower deals 100% of its attack damage as spell damage to the target.\n"
	ability.description_full = "This tower deals an additional amount of spell damage to its target equal to 100% of its attack damage. If the creep is immune this damage is dealt as energy damage equal to 80% of its attack damage not affected by level bonus.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% damage\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var creep: Unit = event.get_target()

	if creep.is_immune():
		tower.do_attack_damage(creep, tower.get_current_attack_damage_with_bonus() * 0.8, tower.calc_attack_multicrit(0, 0, 0))
	else:
		tower.do_spell_damage(creep, tower.get_current_attack_damage_with_bonus() * (1 + _stats.damage_bonus * tower.get_level()), tower.calc_spell_crit_no_bonus())
