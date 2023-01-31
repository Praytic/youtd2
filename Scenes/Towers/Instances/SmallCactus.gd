extends Tower


func _get_base_properties() -> Dictionary:
	return {
		Tower.Property.NAME: "Small Cactus",
		Tower.Property.ID: 41,
		Tower.Property.FAMILY_ID: 41,
		Tower.Property.AUTHOR: "Lapsus",
		Tower.Property.RARITY: "common",
		Tower.Property.ELEMENT: "nature",
		Tower.Property.ATTACK_TYPE: "essence",
		Tower.Property.ATTACK_RANGE: 600.0,
		Tower.Property.ATTACK_CD: 1.0,
		Tower.Property.ATTACK_DAMAGE_MIN: 10,
		Tower.Property.ATTACK_DAMAGE_MAX: 20,
		Tower.Property.COST: 30,
		Tower.Property.DESCRIPTION: "A tiny desert plant with a high AoE. Slightly more efficient against mass creeps and humans.",
		
		Tower.Property.SPLASH: {
			320: 0.5,
		},

		Tower.Property.ON_DAMAGE_CHANCE: 1.0,
		Tower.Property.ON_DAMAGE_CHANCE_LEVEL_ADD: 0.0,
		Tower.Property.ON_ATTACK_CHANCE: 1.0,
		Tower.Property.ON_ATTACK_CHANCE_LEVEL_ADD: 0.0,
	}

func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.15, 0.01)
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.15, 0.01)

	return specials_modifier
