extends Tower

# TODO: visual

func _get_tier_stats() -> Dictionary:
	return {
		1: {bounty_level_add = 0.005},
		2: {bounty_level_add = 0.006},
		3: {bounty_level_add = 0.007},
		4: {bounty_level_add = 0.008},
		5: {bounty_level_add = 0.009},
	}


func _tower_init():
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Unit.ModType.MOD_BOUNTY_RECEIVED, 0.20, _stats.bounty_level_add)
	add_modifier(specials_modifier)
