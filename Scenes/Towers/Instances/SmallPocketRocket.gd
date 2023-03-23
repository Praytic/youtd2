extends Tower

# TODO: visual

func _get_tier_stats() -> Dictionary:
	return {
		1: {dmg_to_mass = 0.20},
		2: {dmg_to_mass = 0.20},
		3: {dmg_to_mass = 0.20},
		4: {dmg_to_mass = 0.20},
		5: {dmg_to_mass = 0.20},
	}


func load_specials():
	_set_attack_style_splash({125: 0.55})

	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, _stats.dmg_to_mass, 0.02)
	add_modifier(modifier)
