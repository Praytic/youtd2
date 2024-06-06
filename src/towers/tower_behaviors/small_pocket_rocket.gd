extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_to_mass = 0.20},
		2: {dmg_to_mass = 0.25},
		3: {dmg_to_mass = 0.30},
		4: {dmg_to_mass = 0.35},
		5: {dmg_to_mass = 0.40},
	}


func load_specials(modifier: Modifier):
	tower.set_attack_style_splash({125: 0.55})

	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, _stats.dmg_to_mass, 0.02)
