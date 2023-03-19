extends Tower

# TODO: implement visual


func _get_tier_stats() -> Dictionary:
	return {
		1: {item_chance_add = 0.005, item_quality_add = -0.005},
		2: {item_chance_add = 0.006, item_quality_add = -0.006},
		3: {item_chance_add = 0.007, item_quality_add = -0.007},
		4: {item_chance_add = 0.008, item_quality_add = -0.008},
		5: {item_chance_add = 0.009, item_quality_add = -0.009},
		6: {item_chance_add = 0.010, item_quality_add = -0.010},
	}


func _tower_init():
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, 0.10, 0.006)
	specials_modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.20, _stats.item_chance_add)
	specials_modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -0.20, _stats.item_quality_add)
	add_modifier(specials_modifier)
