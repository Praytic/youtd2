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
		"splash": {
			320: 0.5,
		},
		"cost": 30,
		"description": "Basic nature tower with a slightly increased chance to critical strike.",
	}

func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_MOVE_SPEED, 0.2, 0.0035)

	return specials_modifier


func _on_attack(event: Event):
	var slow: Buff = Slow.new(self, 5.0, 0.0, 1.0, level)
	var target: Unit = event.target
	target.apply_buff(slow)
