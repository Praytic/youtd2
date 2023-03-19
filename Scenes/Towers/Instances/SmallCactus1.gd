class_name SmallCactus1
extends Tower


func _get_tier_stats() -> Dictionary:
	return {
		1: {value = 0.15, value_add = 0.01},
		2: {value = 0.17, value_add = 0.011},
		3: {value = 0.19, value_add = 0.012},
		4: {value = 0.21, value_add = 0.013},
		5: {value = 0.23, value_add = 0.014},
		6: {value = 0.25, value_add = 0.016},
	}


func _tower_init():
#	NOTE: splash values are the same for all tiers
	_set_attack_style_splash({320: 0.5})

	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, _stats.value, _stats.value_add)
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, _stats.value, _stats.value_add)
	add_modifier(specials_modifier)
