extends Builder


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_MANA, 10, 0)
	mod.add_modification(ModificationType.enm.MOD_MANA_PERC, 1.0, 0.0)
	mod.add_modification(ModificationType.enm.MOD_MANA_REGEN_PERC, 0.50, 0.02)

	mod.add_modification(ModificationType.enm.MOD_SPELL_DAMAGE_DEALT, -0.25, 0.0)

	return mod
