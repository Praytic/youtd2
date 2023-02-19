class_name Event
extends Node

var _buff
# NOTE: damage may be modified in event handlers to change
# the final effect of the event
var damage: float
# target is of type Unit, can't use typing because of cyclic dependency...
var _target
# This flag is to prevent infinite recursion from
# damage/damaged events. For example, if a tower does splash
# damage to mobs around the mob it attacks, then the target
# of the attack will be the main target, while mobs hit by
# splash will not.
var _is_main_target: bool = false


#########################
### Code starts here  ###
#########################

func _init(target, damage_arg, is_main_target_arg: bool):
	_target = target
	damage = damage_arg
	_is_main_target = is_main_target_arg


#########################
### Setters / Getters ###
#########################

func _ready():
	pass

func get_buff():
	return _buff

func get_target():
	return _target

func is_main_target() -> bool:
	return _is_main_target
