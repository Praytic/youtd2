extends Tower


func _get_base_properties() -> Dictionary:
	return {
		Tower.Property.ID: 1,
		Tower.Property.NAME: "Tiny Shrub",
		Tower.Property.FAMILY_ID: 1,
		Tower.Property.AUTHOR: "gex",
		Tower.Property.RARITY: "common",
		Tower.Property.ELEMENT: "nature",
		Tower.Property.ATTACK_TYPE: "physical",
		Tower.Property.ATTACK_RANGE: 800.0,
		Tower.Property.ATTACK_CD: 0.9,
		Tower.Property.ATTACK_DAMAGE_MIN: 26,
		Tower.Property.ATTACK_DAMAGE_MAX: 26,
		Tower.Property.COST: 30,
		Tower.Property.DESCRIPTION: "Basic nature tower with a slightly increased chance to critical strike.",
	}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.02, 0.0035)

	return specials_modifier
