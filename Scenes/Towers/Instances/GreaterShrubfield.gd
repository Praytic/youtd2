extends Tower


func _get_properties() -> Dictionary:
	return {
		"id": 542,
		"name": "Greater Shrubfield",
		"family_id": 1,
		"author": "gex",
		"rarity": "common",
		"element": "nature",
		"attack_type": "physical",
		"base_stats": {
			Tower.Stat.ATTACK_RANGE: 960.0,
			Tower.Stat.ATTACK_CD: 0.9,
			Tower.Stat.ATTACK_DAMAGE_MIN: 901,
			Tower.Stat.ATTACK_DAMAGE_MAX: 901,
		},
		"cost": 1400,
		"description": "Common nature tower with an increased critical strike chance and damage.",
	}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.08, 0.006)
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_DAMAGE, 1.8, 0.06)

	return specials_modifier
