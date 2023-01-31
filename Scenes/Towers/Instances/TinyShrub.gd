extends Tower


func _get_properties() -> Dictionary:
	return {
		"id": 1,
		"name": "Tiny Shrub",
		"family_id": 1,
		"author": "gex",
		"rarity": "common",
		"element": "nature",
		"attack_type": "physical",
		"base_stats": {
			Tower.Stat.ATTACK_RANGE: 800.0,
			Tower.Stat.ATTACK_CD: 0.9,
			Tower.Stat.ATTACK_DAMAGE_MIN: 26,
			Tower.Stat.ATTACK_DAMAGE_MAX: 26,
		},
		"cost": 30,
		"description": "Basic nature tower with a slightly increased chance to critical strike.",
	}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.02, 0.0035)

	return specials_modifier
