extends Builder


func _get_tower_buff() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MANA, 10, 0)
	mod.add_modification(Modification.Type.MOD_MANA_PERC, 1.0, 0.0)
	mod.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.50, 0.02)

	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -0.25, 0.0)
	bt.set_buff_modifier(mod)

	return bt
