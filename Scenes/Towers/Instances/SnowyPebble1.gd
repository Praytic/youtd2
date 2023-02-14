extends Tower

# TODO: implement visual

const _tier_stats_map: Dictionary = {
	1: {dmg_to_mass = 0.30, dmg_to_mass_add = 0.01},
	2: {dmg_to_mass = 0.33, dmg_to_mass_add = 0.011},
	3: {dmg_to_mass = 0.36, dmg_to_mass_add = 0.012},
	4: {dmg_to_mass = 0.39, dmg_to_mass_add = 0.013},
	5: {dmg_to_mass = 0.42, dmg_to_mass_add = 0.014},
	6: {dmg_to_mass = 0.45, dmg_to_mass_add = 0.015},
}


func _ready():
#	NOTE: splash values are the same for all tiers
	var splash_attack_buff = SplashAttack.new({600: 0.1})
	splash_attack_buff.apply_to_unit_permanent(self, self, 0, true)


func _get_specials_modifier() -> Modifier:
	var tier: int = get_tier()
	var stats = _tier_stats_map[tier]

	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, stats.dmg_to_mass, stats.dmg_to_mass_add)

	return specials_modifier
