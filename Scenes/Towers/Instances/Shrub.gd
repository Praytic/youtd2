extends Tower


func _get_base_properties() -> Dictionary:
	return {
		Tower.Property.NAME: "Shrub",
		Tower.Property.ID: 439,
		Tower.Property.FAMILY_ID: 1,
		Tower.Property.AUTHOR: "gex",
		Tower.Property.RARITY: "common",
		Tower.Property.ELEMENT: "nature",
		Tower.Property.ATTACK_TYPE: "physical",
		Tower.Property.ATTACK_RANGE: 840.0,
		Tower.Property.ATTACK_CD: 0.9,
		Tower.Property.ATTACK_DAMAGE_MIN: 113,
		Tower.Property.ATTACK_DAMAGE_MAX: 113,
		Tower.Property.COST: 140,
		Tower.Property.DESCRIPTION: "Common nature tower with an increased critical strike chance and damage.",
	}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.04, 0.003)
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_DAMAGE, 1.4, 0.03)

	return specials_modifier
