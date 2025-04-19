extends Builder


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL, 0.15, 0.0)
	mod.add_modification(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, 0.20, 0.0)

	return mod
