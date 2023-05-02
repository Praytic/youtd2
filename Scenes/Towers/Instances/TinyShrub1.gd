extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {crit_chance = 0.02, crit_chance_add = 0.0035, crit_damage = 0.0, crit_damage_add = 0.0},
		2: {crit_chance = 0.04, crit_chance_add = 0.003, crit_damage = 1.4, crit_damage_add = 0.03},
		3: {crit_chance = 0.05, crit_chance_add = 0.004, crit_damage = 1.5, crit_damage_add = 0.04},
		4: {crit_chance = 0.07, crit_chance_add = 0.005, crit_damage = 1.7, crit_damage_add = 0.05},
		5: {crit_chance = 0.08, crit_chance_add = 0.006, crit_damage = 1.8, crit_damage_add = 0.06},
		6: {crit_chance = 0.10, crit_chance_add = 0.007, crit_damage = 2.0, crit_damage_add = 0.07},
	}


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, _stats.crit_chance, _stats.crit_chance_add)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, _stats.crit_damage, _stats.crit_damage_add)
