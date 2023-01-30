extends Tower


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
			Tower.Stat.ATTACK_RANGE: 600.0,
			Tower.Stat.ATTACK_CD: 1.0,
			Tower.Stat.ATTACK_DAMAGE_MIN: 10,
			Tower.Stat.ATTACK_DAMAGE_MAX: 20,
		},
		"trigger_parameters": {
			Tower.TriggerParameter.ON_DAMAGE_CHANCE: 1.0,
			Tower.TriggerParameter.ON_DAMAGE_CHANCE_LEVEL_ADD: 0.0,
			Tower.TriggerParameter.ON_ATTACK_CHANCE: 1.0,
			Tower.TriggerParameter.ON_ATTACK_CHANCE_LEVEL_ADD: 0.0,
		},
		"splash": {
			320: 0.5,
		},
		"cost": 30,
		"description": "A tiny desert plant with a high AoE. Slightly more efficient against mass creeps and humans.",
	}

func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.15, 0.01)
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.15, 0.01)

	return specials_modifier
