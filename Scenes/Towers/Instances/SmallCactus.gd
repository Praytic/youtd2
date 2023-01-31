extends Tower


func _get_properties() -> Dictionary:
	return {
		Tower.Stat.ID: 41,
		Tower.Stat.NAME: "Small Cactus",
		Tower.Stat.FAMILY_ID: 41,
		Tower.Stat.AUTHOR: "Lapsus",
		Tower.Stat.RARITY: "common",
		Tower.Stat.ELEMENT: "nature",
		Tower.Stat.ATTACK_TYPE: "essence",
		Tower.Stat.ATTACK_RANGE: 600.0,
		Tower.Stat.ATTACK_CD: 1.0,
		Tower.Stat.ATTACK_DAMAGE_MIN: 10,
		Tower.Stat.ATTACK_DAMAGE_MAX: 20,
		Tower.Stat.ON_DAMAGE_CHANCE: 1.0,
		Tower.Stat.ON_DAMAGE_CHANCE_LEVEL_ADD: 0.0,
		Tower.Stat.ON_ATTACK_CHANCE: 1.0,
		Tower.Stat.ON_ATTACK_CHANCE_LEVEL_ADD: 0.0,
		Tower.Stat.SPLASH: {
			320: 0.5,
		},
		Tower.Stat.COST: 30,
		Tower.Stat.DESCRIPTION: "A tiny desert plant with a high AoE. Slightly more efficient against mass creeps and humans.",
	}

func _get_specials_modifier() -> Modifier:
	var specials_modifier: Modifier = Modifier.new()
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.15, 0.01)
	specials_modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.15, 0.01)

	return specials_modifier
