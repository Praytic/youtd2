extends Item


# TODO: visual

var _modifier: Modifier


func _ready():
	_modifier = Modifier.new()
	_modifier.add_modification(Modification.Type.MOD_ATTACK_SPEED, -0.16, 0.0)
	_modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, -0.16, 0.0)


func _add_to_tower_subclass():
	get_carrier().add_modifier(_modifier)


func _remove_from_tower_subclass():
	get_carrier().remove_modifier(_modifier)
