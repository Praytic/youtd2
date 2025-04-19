extends Builder


# NOTE: [ORIGINAL_GAME_DEVIATION] the following builder
# effect from original game is not implemented: "Unable to
# share build areas with allies"


func _init():
	_allow_adjacent_towers = false


func apply_to_player(player: Player):
	player.modify_food_cap(-20)
	player.set_builder_wisdom_multiplier(0.625)


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_DMG_TO_BOSS, 0.50, 0.0)
	mod.add_modification(ModificationType.enm.MOD_DMG_TO_CHAMPION, 0.25, 0.0)
	mod.add_modification(ModificationType.enm.MOD_DEBUFF_DURATION, -0.30, 0.0)
	mod.add_modification(ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL, 0.0, 0.01)
	mod.add_modification(ModificationType.enm.MOD_DAMAGE_BASE_PERC, 0.0, 0.03)
	mod.add_modification(ModificationType.enm.MOD_SPELL_DAMAGE_DEALT, 0.0, 0.03)

	mod.add_modification(ModificationType.enm.MOD_BUFF_DURATION, -0.50, 0.03)

	return mod
