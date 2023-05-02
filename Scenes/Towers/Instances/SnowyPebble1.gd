extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_to_mass = 0.30, dmg_to_mass_add = 0.01},
		2: {dmg_to_mass = 0.33, dmg_to_mass_add = 0.011},
		3: {dmg_to_mass = 0.36, dmg_to_mass_add = 0.012},
		4: {dmg_to_mass = 0.39, dmg_to_mass_add = 0.013},
		5: {dmg_to_mass = 0.42, dmg_to_mass_add = 0.014},
		6: {dmg_to_mass = 0.45, dmg_to_mass_add = 0.015},
	}


func load_specials(modifier: Modifier):
	_set_attack_style_splash({600: 0.1})
	
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, _stats.dmg_to_mass, _stats.dmg_to_mass_add)
