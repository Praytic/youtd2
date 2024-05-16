extends Builder


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.10, 0.04)
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.10, 0.005)
	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.25, 0.0)

	mod.add_modification(Modification.Type.MOD_EXP_RECEIVED, -0.60, -0.016)
	mod.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, -0.16, 0.0)

	return mod
