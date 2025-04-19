extends Builder


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 0.20, 0.02)

	return mod


func _get_creep_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_MOVESPEED_ABSOLUTE, 50, 0)

	return mod
