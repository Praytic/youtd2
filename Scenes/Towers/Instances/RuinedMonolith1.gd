extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {bounce_damage_multiplier = 0.50},
		2: {bounce_damage_multiplier = 0.46},
		3: {bounce_damage_multiplier = 0.42},
		4: {bounce_damage_multiplier = 0.38},
		5: {bounce_damage_multiplier = 0.34},
		6: {bounce_damage_multiplier = 0.30},
	}


func load_specials(modifier: Modifier):
	_set_attack_style_bounce(3, _stats.bounce_damage_multiplier)
	
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.10, 0.01)
