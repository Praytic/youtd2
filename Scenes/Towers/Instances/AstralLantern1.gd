extends Tower

func _get_tier_stats() -> Dictionary:
	return {
		1: {damage_base = 0.15, damage_add = 0.006},
		2: {damage_base = 0.20, damage_add = 0.008},
		3: {damage_base = 0.25, damage_add = 0.010},
		4: {damage_base = 0.30, damage_add = 0.012},
	}


func _load_triggers(triggers_buff: Buff):
	triggers_buff.add_event_on_damage(self, "_on_damage", 1.0, 0.0)


func _on_damage(event: Event):
	var tower: Unit = self

	if event.get_target().is_invisible():
		event.damage = event.damage * (_stats.damage_base * _stats.damage_add * tower.get_level())
