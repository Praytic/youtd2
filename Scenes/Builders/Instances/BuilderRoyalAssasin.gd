extends Builder


func _get_tower_buff() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_BOSS, 0.15, 0.01)
	mod.add_modification(Modification.Type.MOD_DMG_TO_CHAMPION, 0.25, 0.0)
	mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.0, 0.02)

	mod.add_modification(Modification.Type.MOD_DMG_TO_NORMAL, -0.08, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_MASS, -0.12, 0.0)
	bt.set_buff_modifier(mod)

	return bt
