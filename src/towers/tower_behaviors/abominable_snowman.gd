extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {bounce_damage_multiplier = 0.25},
		2: {bounce_damage_multiplier = 0.20},
		3: {bounce_damage_multiplier = 0.15},
		4: {bounce_damage_multiplier = 0.10},
		5: {bounce_damage_multiplier = 0.05},
	}


func load_specials_DELETEME(_modifier: Modifier):
	tower.set_attack_style_bounce_DELETEME(2, _stats.bounce_damage_multiplier)
