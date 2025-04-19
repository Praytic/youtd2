extends Builder


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_DEBUFF_DURATION, -0.30, 0.0)
	mod.add_modification(ModificationType.enm.MOD_BUFF_DURATION, 0.80, 0.0)
	mod.add_modification(ModificationType.enm.MOD_DMG_TO_MASS, 0.10, 0.0)

	mod.add_modification(ModificationType.enm.MOD_DMG_TO_BOSS, -0.10, 0.0)

	return mod
