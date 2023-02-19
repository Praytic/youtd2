extends Item


# TODO: visual


func _ready():
	_modifier.add_modification(Modification.Type.MOD_ATTACK_SPEED, -0.16, 0.0)
	_modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, -0.16, 0.0)
