extends Tower

# Skills go here


func _get_properties() -> Dictionary:
	return {
		"id": 511,
		"name": "Greater Shrub",
		"family_id": 1,
		"author": "gex",
		"rarity": "common",
		"element": "nature",
		"attack_type": "physical",
		"base_stats": {
			Properties.TowerStat.ATTACK_RANGE: 600.0,
			Properties.TowerStat.ATTACK_CD: 1.0,
			Properties.TowerStat.ATTACK_DAMAGE_MIN: 10,
			Properties.TowerStat.ATTACK_DAMAGE_MAX: 20,
		},
		"trigger_parameters": {
			Properties.TriggerParameter.ON_DAMAGE_CHANCE: 1.0,
			Properties.TriggerParameter.ON_DAMAGE_CHANCE_LEVEL_ADD: 0.0,
			Properties.TriggerParameter.ON_ATTACK_CHANCE: 1.0,
			Properties.TriggerParameter.ON_ATTACK_CHANCE_LEVEL_ADD: 0.0,
		},
		"splash": {},
		"cost": 400,
		"description": "Common nature tower with an increased critical strike chance and damage.",
	}
	