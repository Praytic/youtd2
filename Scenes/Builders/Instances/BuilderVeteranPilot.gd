extends Builder


func _get_tower_buff() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.20, 0.02)
	bt.set_buff_modifier(mod)

	return bt


func _get_creep_buff() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED_ABSOLUTE, 50, 0)
	bt.set_buff_modifier(mod)

	return bt
