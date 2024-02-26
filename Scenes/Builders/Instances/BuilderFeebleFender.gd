extends Builder


# TODO: the following bonus is not implemented: "+2 keeper
# of wisdom max upgrades" because Keeper of Wisdom is not
# implemented. Keeper of Wisdom is a feature in youtd where
# player can buy minor stat perks, based on player level.


func _init():
	GoldControl.modify_income_rate(-0.20)
	KnowledgeTomesManager.add_knowledge_tomes(-45)


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.50, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.30, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.50, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, -0.30, 0.0)

	return mod
