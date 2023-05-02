extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_bonus = 0.35, dmg_bonus_add = 0.012},
		2: {dmg_bonus = 0.35, dmg_bonus_add = 0.012},
		3: {dmg_bonus = 0.35, dmg_bonus_add = 0.012},
		4: {dmg_bonus = 0.40, dmg_bonus_add = 0.0135},
		5: {dmg_bonus = 0.40, dmg_bonus_add = 0.0135},
	}


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.5, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, _stats.dmg_bonus, _stats.dmg_bonus_add)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, _stats.dmg_bonus, _stats.dmg_bonus_add)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, _stats.dmg_bonus, _stats.dmg_bonus_add)
