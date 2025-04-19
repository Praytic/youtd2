extends Builder


func apply_to_player(player: Player):
	player.add_tomes(65)
	player.modify_food_cap(20)


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_DMG_TO_ORC, 0.25, 0.0)
	mod.add_modification(ModificationType.enm.MOD_DMG_TO_UNDEAD, 0.20, 0.0)

	mod.add_modification(ModificationType.enm.MOD_DMG_TO_NATURE, -0.20, 0.0)
	mod.add_modification(ModificationType.enm.MOD_DMG_TO_HUMANOID, -0.05, 0.0)

	return mod


func apply_wave_finished_effect(player: Player):
	player.add_tomes(2)
