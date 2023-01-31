extends Tower


func _get_base_properties() -> Dictionary:
	return {
		Tower.Property.ID: 565,
		Tower.Property.NAME: "Xtreme Shrubfield",
		Tower.Property.FAMILY_ID: 1,
		Tower.Property.AUTHOR: "gex",
		Tower.Property.RARITY: "common",
		Tower.Property.ELEMENT: "nature",
		Tower.Property.ATTACK_TYPE: "physical",
		Tower.Property.ATTACK_RANGE: 1000.0,
		Tower.Property.ATTACK_CD: 0.9,
		Tower.Property.ATTACK_DAMAGE_MIN: 1360,
		Tower.Property.ATTACK_DAMAGE_MAX: 1360,
		Tower.Property.COST: 2300,
		Tower.Property.DESCRIPTION: "Common nature tower with an increased critical strike chance and damage.",
	}


func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.10, 0.007)
	specials_modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_DAMAGE, 2.0, 0.07)

	return specials_modifier
