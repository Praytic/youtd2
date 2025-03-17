extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {exp = 0.40},
		2: {exp = 0.55},
		3: {exp = 0.70},
		4: {exp = 0.85},
		5: {exp = 1.00},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func on_attack(_event: Event):
	tower.add_exp(_stats.exp)
