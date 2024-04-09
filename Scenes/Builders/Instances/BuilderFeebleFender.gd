extends Builder


func apply_to_player(player: Player):
	player.modify_income_rate(-0.20)
	player.add_tomes(-45)
	player.modify_wisdom_upgrade_max(2)


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.50, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.30, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.50, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, -0.30, 0.0)

	return mod
