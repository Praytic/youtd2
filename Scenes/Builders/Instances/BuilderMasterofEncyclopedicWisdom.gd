extends Builder


func _init():
	Globals._builder_tower_lvl_bonus = 5


func _get_tower_buff() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.60, 0.01)

	mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, -0.15, 0.0)
	bt.set_buff_modifier(mod)

	return bt
