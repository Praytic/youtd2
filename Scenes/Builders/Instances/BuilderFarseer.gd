extends Builder


func _init():
	Globals._builder_range_bonus = 75


func _get_tower_buff() -> BuffType:
	var bt: BuffType = MagicalSightBuff.new("", 700, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.10, 0.0)
	bt.set_buff_modifier(mod)

	return bt
