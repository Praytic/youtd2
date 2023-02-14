extends Tower


const _stats_map: Dictionary = {
	1: {crit_chance = 0.02, crit_chance_add = 0.0035, crit_damage = 0.0, crit_damage_add = 0.0},
	2: {crit_chance = 0.04, crit_chance_add = 0.003, crit_damage = 1.4, crit_damage_add = 0.03},
	3: {crit_chance = 0.05, crit_chance_add = 0.004, crit_damage = 1.5, crit_damage_add = 0.04},
	4: {crit_chance = 0.07, crit_chance_add = 0.005, crit_damage = 1.7, crit_damage_add = 0.05},
	5: {crit_chance = 0.08, crit_chance_add = 0.006, crit_damage = 1.8, crit_damage_add = 0.06},
	6: {crit_chance = 0.10, crit_chance_add = 0.007, crit_damage = 2.0, crit_damage_add = 0.07},
}


func _get_specials_modifier() -> Modifier:
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, stats.crit_chance, stats.crit_chance_add)
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_DAMAGE, stats.crit_damage, stats.crit_damage_add)

	return specials_modifier
