extends Tower


func _get_properties() -> Dictionary:
	return {
		Tower.Stat.ID: 439,
		Tower.Stat.NAME: "Shrub",
		Tower.Stat.FAMILY_ID: 1,
		Tower.Stat.AUTHOR: "gex",
		Tower.Stat.RARITY: "common",
		Tower.Stat.ELEMENT: "nature",
		Tower.Stat.ATTACK_TYPE: "physical",
		Tower.Stat.ATTACK_RANGE: 840.0,
		Tower.Stat.ATTACK_CD: 0.9,
		Tower.Stat.ATTACK_DAMAGE_MIN: 113,
		Tower.Stat.ATTACK_DAMAGE_MAX: 113,
		Tower.Stat.COST: 140,
		Tower.Stat.DESCRIPTION: "Common nature tower with an increased critical strike chance and damage.",
	}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.04, 0.003)
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_DAMAGE, 1.4, 0.03)

	return specials_modifier
