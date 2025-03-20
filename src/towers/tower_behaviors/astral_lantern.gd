extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Commented out sections
# relevant to invisibility because invisible waves are not
# implemented.


# func get_tier_stats() -> Dictionary:
# 	return {
# 		1: {damage_base = 0.15, damage_add = 0.006},
# 		2: {damage_base = 0.20, damage_add = 0.008},
# 		3: {damage_base = 0.25, damage_add = 0.010},
# 		4: {damage_base = 0.30, damage_add = 0.012},
# 	}


# func load_triggers(triggers_buff_type: BuffType):
# 	triggers_buff_type.add_event_on_damage(on_damage)


# func on_damage(event: Event):
# 	if event.get_target().is_invisible():
# 		event.damage = event.damage * (_stats.damage_base + tower.get_level() * _stats.damage_add)
