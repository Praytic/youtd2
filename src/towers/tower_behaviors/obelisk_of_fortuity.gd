extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {miss_chance_base = 0.3},
		2: {miss_chance_base = 0.4},
		3: {miss_chance_base = 0.5},
		4: {miss_chance_base = 0.6},
		5: {miss_chance_base = 0.7},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_damage(event: Event):
	if tower.calc_bad_chance(_stats.miss_chance_base - tower.get_level() * 0.006):
		CombatLog.log_ability(tower, event.get_target(), "Warming Up")
		event.damage = 0
		tower.get_player().display_floating_text_x(tr("FLOATING_TEXT_MISS"), tower, Color8(255, 0, 0, 255), 0.05, 0.0, 2.0)
