extends StaticBody2D


func _get_properties() -> Dictionary:
	return {
		"id": 41,
		"name": "Small Cactus",
		"family_id": 41,
		"author": "Lapsus",
		"rarity": "common",
		"element": "nature",
		"attack_type": "essence",
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
		"cost": 30,
		"description": "A tiny desert plant with a high AoE. Slightly more efficient against mass creeps and humans.",
		"effects": [],
	
	}
