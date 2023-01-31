extends Tower


func _get_base_properties() -> Dictionary:
	return {
		Tower.Property.ID: 542,
		Tower.Property.NAME: "Greater Shrubfield",
		Tower.Property.FAMILY_ID: 1,
		Tower.Property.AUTHOR: "gex",
		Tower.Property.RARITY: "common",
		Tower.Property.ELEMENT: "nature",
		Tower.Property.ATTACK_TYPE: "physical",
		Tower.Property.ATTACK_RANGE: 960.0,
		Tower.Property.ATTACK_CD: 0.9,
		Tower.Property.ATTACK_DAMAGE_MIN: 901,
		Tower.Property.ATTACK_DAMAGE_MAX: 901,
		Tower.Property.COST: 1400,
		Tower.Property.DESCRIPTION: "Common nature tower with an increased critical strike chance and damage.",
	}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.08, 0.006)
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_DAMAGE, 1.8, 0.06)

	return specials_modifier
