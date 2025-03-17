extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {mana_burned = 6, mana_burned_add = 0.08, dmg_bonus_per_mana = 0.08},
		2: {mana_burned = 8, mana_burned_add = 0.12, dmg_bonus_per_mana = 0.09},
		3: {mana_burned = 10, mana_burned_add = 0.16, dmg_bonus_per_mana = 0.10},
		4: {mana_burned = 12, mana_burned_add = 0.20, dmg_bonus_per_mana = 0.12},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var target: Unit = event.get_target()

	var level: int = tower.get_level()
	var mana_burned: float = _stats.mana_burned + _stats.mana_burned_add * level
	var mana_burned_actual: float = target.subtract_mana(mana_burned, true)
	var dmg_multiplier: float = 1.0 + _stats.dmg_bonus_per_mana * mana_burned_actual

	event.damage *= dmg_multiplier
