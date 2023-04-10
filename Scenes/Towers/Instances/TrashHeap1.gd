extends Tower


func _get_tier_stats() -> Dictionary:
	return {
		1: {item_chance_add = 0.005, item_quality_add = -0.005},
		2: {item_chance_add = 0.006, item_quality_add = -0.006},
		3: {item_chance_add = 0.007, item_quality_add = -0.007},
		4: {item_chance_add = 0.008, item_quality_add = -0.008},
		5: {item_chance_add = 0.009, item_quality_add = -0.009},
		6: {item_chance_add = 0.010, item_quality_add = -0.010},
	}


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, 0.10, 0.006)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.20, _stats.item_chance_add)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -0.20, _stats.item_quality_add)
