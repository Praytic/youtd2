extends Tower


# NOTE: this tower's tooltip in original game includes
# innate stats in some cases
# crit chance = yes
# crit chance add = yes for tier1, no for tiers>1 (yes, it's that weird)
# crit dmg = yes
# crit dmg add = no


func get_tier_stats() -> Dictionary:
	return {
		1: {crit_chance = 0.0075, crit_chance_add = 0.002, crit_damage = 0.0, crit_damage_add = 0.0},
		2: {crit_chance = 0.0275, crit_chance_add = 0.003, crit_damage = 0.15, crit_damage_add = 0.03},
		3: {crit_chance = 0.0375, crit_chance_add = 0.004, crit_damage = 0.25, crit_damage_add = 0.04},
		4: {crit_chance = 0.0575, crit_chance_add = 0.005, crit_damage = 0.45, crit_damage_add = 0.05},
		5: {crit_chance = 0.0675, crit_chance_add = 0.006, crit_damage = 0.55, crit_damage_add = 0.06},
		6: {crit_chance = 0.0875, crit_chance_add = 0.007, crit_damage = 0.75, crit_damage_add = 0.07},
	}


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, _stats.crit_chance, _stats.crit_chance_add)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, _stats.crit_damage, _stats.crit_damage_add)
