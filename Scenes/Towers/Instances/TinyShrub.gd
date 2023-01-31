extends Tower


func _get_properties() -> Dictionary:
	return {
		Tower.Stat.ID: 1,
		Tower.Stat.NAME: "Tiny Shrub",
		Tower.Stat.FAMILY_ID: 1,
		Tower.Stat.AUTHOR: "gex",
		Tower.Stat.RARITY: "common",
		Tower.Stat.ELEMENT: "nature",
		Tower.Stat.ATTACK_TYPE: "physical",
		Tower.Stat.ATTACK_RANGE: 800.0,
		Tower.Stat.ATTACK_CD: 0.9,
		Tower.Stat.ATTACK_DAMAGE_MIN: 26,
		Tower.Stat.ATTACK_DAMAGE_MAX: 26,
		Tower.Stat.COST: 30,
		Tower.Stat.DESCRIPTION: "Basic nature tower with a slightly increased chance to critical strike.",
	}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.02, 0.0035)

	return specials_modifier
