extends Builder


func _init():
	_tower_lvl_bonus = 5


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_EXP_RECEIVED, 0.60, 0.01)

	mod.add_modification(ModificationType.enm.MOD_DAMAGE_BASE_PERC, -0.15, 0.0)

	return mod
