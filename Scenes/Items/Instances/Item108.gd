# Expanindg Mind
extends Item


func _item_init():
	_modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.50, -0.02)
