extends Tower


func _get_tier_stats() -> Dictionary:
	return {
		1: {bounty_level_add = 0.005},
		2: {bounty_level_add = 0.006},
		3: {bounty_level_add = 0.007},
		4: {bounty_level_add = 0.008},
		5: {bounty_level_add = 0.009},
	}


func load_specials():
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.20, _stats.bounty_level_add)
	add_modifier(modifier)
