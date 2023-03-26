extends Tower


func _get_tier_stats() -> Dictionary:
	return {
		1: {bounce_damage_multiplier = 0.25},
		2: {bounce_damage_multiplier = 0.20},
		3: {bounce_damage_multiplier = 0.15},
		4: {bounce_damage_multiplier = 0.10},
		5: {bounce_damage_multiplier = 0.05},
	}


func load_specials():
	_set_attack_style_bounce(2, _stats.bounce_damage_multiplier)
