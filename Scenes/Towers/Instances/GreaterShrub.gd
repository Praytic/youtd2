extends Tower


func _get_base_properties() -> Dictionary:
	return {
		Tower.Property.ID: 459,
		Tower.Property.NAME: "Greater Shrub",
		Tower.Property.FAMILY_ID: 1,
		Tower.Property.AUTHOR: "gex",
		Tower.Property.RARITY: "common",
		Tower.Property.ELEMENT: "nature",
		Tower.Property.ATTACK_TYPE: "physical",
		Tower.Property.ATTACK_RANGE: 880.0,
		Tower.Property.ATTACK_CD: 0.9,
		Tower.Property.ATTACK_DAMAGE_MIN: 299,
		Tower.Property.ATTACK_DAMAGE_MAX: 299,
		Tower.Property.COST: 400,
		Tower.Property.DESCRIPTION: "Common nature tower with an increased critical strike chance and damage.",
	}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.05, 0.004)
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_DAMAGE, 1.5, 0.04)

	return specials_modifier
