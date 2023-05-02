extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {exp_received = 0.40, damage_add = 0.050},
		2: {exp_received = 0.42, damage_add = 0.055},
		3: {exp_received = 0.44, damage_add = 0.060},
		4: {exp_received = 0.46, damage_add = 0.065},
		5: {exp_received = 0.48, damage_add = 0.070},
		6: {exp_received = 0.50, damage_add = 0.075},
	}


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, _stats.exp_received, -0.025)
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, _stats.damage_add)
