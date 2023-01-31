extends Tower


func _get_properties() -> Dictionary:
	return {
		Tower.Stat.ID: 459,
		Tower.Stat.NAME: "Greater Shrub",
		Tower.Stat.FAMILY_ID: 1,
		Tower.Stat.AUTHOR: "gex",
		Tower.Stat.RARITY: "common",
		Tower.Stat.ELEMENT: "nature",
		Tower.Stat.ATTACK_TYPE: "physical",
		Tower.Stat.ATTACK_RANGE: 880.0,
		Tower.Stat.ATTACK_CD: 0.9,
		Tower.Stat.ATTACK_DAMAGE_MIN: 299,
		Tower.Stat.ATTACK_DAMAGE_MAX: 299,
		Tower.Stat.COST: 400,
		Tower.Stat.DESCRIPTION: "Common nature tower with an increased critical strike chance and damage.",
	}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.05, 0.004)
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_DAMAGE, 1.5, 0.04)

	return specials_modifier
