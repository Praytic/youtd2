extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {chance_base = 0.008, chance_add = 0.0015},
		2: {chance_base = 0.010, chance_add = 0.0017},
		3: {chance_base = 0.012, chance_add = 0.0020},
		4: {chance_base = 0.014, chance_add = 0.0022},
		5: {chance_base = 0.016, chance_add = 0.0024},
		6: {chance_base = 0.020, chance_add = 0.0025},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var chance_base: String = Utils.format_percent(_stats.chance_base, 2)
	var chance_add: String = Utils.format_percent(_stats.chance_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Tomb's Curse"
	ability.icon = "res://Resources/Icons/AbilityIcons/AshGeyser_purple.tres"
	ability.description_short = "Small chance to instantly kill a lesser creep on attack.\n"
	ability.description_full = "This tower has a %s chance on attack to kill a non boss, non champion target immediately.\n" % chance_base \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s chance" % chance_add
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_damage(event: Event):
	if !tower.calc_chance(_stats.chance_base + tower.get_level() * _stats.chance_add):
		return

	var creep: Unit = event.get_target()
	var size: int = creep.get_size()

	if size < CreepSize.enm.CHAMPION:
		CombatLog.log_ability(tower, creep, "Tomb's Curse")
		tower.kill_instantly(creep)
		SFX.sfx_at_unit("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", creep)
