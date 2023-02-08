class_name Event
extends Node

var damage: float
# target is of type Unit, can't use typing because of cyclic dependency...
var target
# This flag is to prevent infinite recursion from
# damage/damaged events. For example, if a tower does splash
# damage to mobs around the mob it attacks, then the target
# of the attack will be the main target, while mobs hit by
# splash will not.
var is_main_target: bool = false


func _ready():
	pass
