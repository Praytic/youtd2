# Claws of Wisdom
extends Item


func _item_init():
	_modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.16, 0.0)
	_modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, -0.16, 0.0)
