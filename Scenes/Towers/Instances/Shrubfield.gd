extends Tower


func _get_properties() -> Dictionary:
	return {
		"id": 511,
		"name": "Shrubfield",
		"family_id": 1,
		"author": "gex",
		"rarity": "common",
		"element": "nature",
		"attack_type": "physical",
		"base_stats": {
			Tower.Stat.ATTACK_RANGE: 920.0,
			Tower.Stat.ATTACK_CD: 0.9,
			Tower.Stat.ATTACK_DAMAGE_MIN: 552,
			Tower.Stat.ATTACK_DAMAGE_MAX: 552,
		},
		"cost": 800,
		"description": "Common nature tower with an increased critical strike chance and damage.",
	}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.07, 0.005)
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_DAMAGE, 1.7, 0.05)

	return specials_modifier
