extends Builder


func _get_tower_buff() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.15, 0.0)
	mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.20, 0.0)
	bt.set_buff_modifier(mod)

	return bt
