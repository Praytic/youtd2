extends Item


# TODO: visual


func _item_init():
	_modifier.add_modification(Unit.ModType.MOD_ATTACKSPEED, -0.16, 0.0)
	_modifier.add_modification(Unit.ModType.MOD_EXP_RECEIVED, -0.16, 0.0)
