extends Builder


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.08, 0.0)
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.40, 0.0)
	mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)

	return mod
