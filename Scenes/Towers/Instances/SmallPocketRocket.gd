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


func _tower_init():
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Unit.ModType.MOD_DMG_TO_MASS, _stats.dmg_to_mass, 0.02)
	add_modifier(specials_modifier)

	var splash_attack_buff = SplashAttack.new({125: 0.55})
	splash_attack_buff.apply_to_unit_permanent(self, self, 0)
