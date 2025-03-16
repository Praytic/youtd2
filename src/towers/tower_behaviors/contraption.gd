extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {mana_burned = 6, mana_burned_add = 0.08, dmg_bonus_per_mana = 0.08},
		2: {mana_burned = 8, mana_burned_add = 0.12, dmg_bonus_per_mana = 0.09},
		3: {mana_burned = 10, mana_burned_add = 0.16, dmg_bonus_per_mana = 0.10},
		4: {mana_burned = 12, mana_burned_add = 0.20, dmg_bonus_per_mana = 0.12},
	}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var mana_burned: String = Utils.format_float(_stats.mana_burned, 2)
	var mana_burned_add: String = Utils.format_float(_stats.mana_burned_add, 2)
	var dmg_bonus_per_mana: String = Utils.format_percent(_stats.dmg_bonus_per_mana, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Mana Break"
	ability.icon = "res://resources/icons/rockets/rocket_07.tres"
	ability.description_short = "Whenever this tower hits a creep, it burns mana and deals extra damage for every point of mana burned.\n"
	ability.description_full = "Whenever this tower hits a creep, it burns %s mana and deals %s more damage for every point of mana burned.\n" % [mana_burned, dmg_bonus_per_mana] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s mana burned\n" % mana_burned_add \
	+ ""
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var target: Unit = event.get_target()

	var level: int = tower.get_level()
	var mana_burned: float = _stats.mana_burned + _stats.mana_burned_add * level
	var mana_burned_actual: float = target.subtract_mana(mana_burned, true)
	var dmg_multiplier: float = 1.0 + _stats.dmg_bonus_per_mana * mana_burned_actual

	event.damage *= dmg_multiplier
