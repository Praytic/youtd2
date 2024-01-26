extends Builder


func _get_tower_buff() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.30, 0.0)
	mod.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.80, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.10, 0.0)

	mod.add_modification(Modification.Type.MOD_DMG_TO_BOSS, -0.10, 0.0)
	bt.set_buff_modifier(mod)

	return bt
