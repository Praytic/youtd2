extends Tower


func _get_properties() -> Dictionary:
	return {
		"id": 565,
		"name": "Xtreme Shrubfield",
		"family_id": 1,
		"author": "gex",
		"rarity": "common",
		"element": "nature",
		"attack_type": "physical",
		"base_stats": {
			Tower.Stat.ATTACK_RANGE: 1000.0,
			Tower.Stat.ATTACK_CD: 0.9,
			Tower.Stat.ATTACK_DAMAGE_MIN: 1360,
			Tower.Stat.ATTACK_DAMAGE_MAX: 1360,
		},
		"cost": 2300,
		"description": "Common nature tower with an increased critical strike chance and damage.",
	}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.10, 0.007)
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_DAMAGE, 2.0, 0.07)

	return specials_modifier
