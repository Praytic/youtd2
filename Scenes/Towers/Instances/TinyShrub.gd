extends Tower


func get_properties() -> Dictionary:
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
		"effects": [
			{
				Properties.EffectParameter.TYPE: Properties.EffectType.MOD_TOWER_STAT,
				Properties.EffectParameter.AFFECTED_TOWER_STAT: Properties.TowerStat.CRIT_CHANCE,
				Properties.EffectParameter.VALUE_BASE: 0.2,
				Properties.EffectParameter.VALUE_PER_LEVEL: 0.0035,
			}
		],
	}

func on_attack(event: Event):
	var slow: Buff = Slow.new(self, 5.0, 0.0, 1.0, level)
	var target: Unit = event.target
	target.apply_buff(slow)
