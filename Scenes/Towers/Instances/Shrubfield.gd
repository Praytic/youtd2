extends Tower


func _get_properties() -> Dictionary:
	return {
		Tower.Stat.ID: 511,
		Tower.Stat.NAME: "Shrubfield",
		Tower.Stat.FAMILY_ID: 1,
		Tower.Stat.AUTHOR: "gex",
		Tower.Stat.RARITY: "common",
		Tower.Stat.ELEMENT: "nature",
		Tower.Stat.ATTACK_TYPE: "physical",
		Tower.Stat.ATTACK_RANGE: 920.0,
		Tower.Stat.ATTACK_CD: 0.9,
		Tower.Stat.ATTACK_DAMAGE_MIN: 552,
		Tower.Stat.ATTACK_DAMAGE_MAX: 552,
		Tower.Stat.COST: 800,
		Tower.Stat.DESCRIPTION: "Common nature tower with an increased critical strike chance and damage.",
	}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.07, 0.005)
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_DAMAGE, 1.7, 0.05)

	return specials_modifier
