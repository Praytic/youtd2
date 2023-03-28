class_name Aura
extends Node2D

# Aura applies an effect to targets in range of caster.
# Create an aura instance, set it's variables and add as
# child of the caster scene to use the aura. Caster should
# define a function which creates a buff for the aura effect
# and set aura's create_aura_effect_function variable to the
# name of this function.

# TODO: current implementation has a lag of 0.2s because it
# is based on a timer. (Godot timer's aren't supposed to
# have wait times of lower than 0.2s and it would cause
# perfomance issues anyway). An implementation without lag
# would need to not use a timer and instead connect to
# body_entered/exited() signals of the Area2D. That
# implementation is considerably more complex to implement
# because of the need to handle overlapping aura's from
# different towers. For example, if a creep is inside two
# intersecting aura's of same type, and exits one of them,
# the aura effect has to be swapped to the aura that the creep
# remains in. Also need to handle aura upgrades when creep
# enters aura of same type but higher level effect.


var _aura_range: float = 10.0
var _target_type: TargetType = null
var _target_self: bool = false
var _level: int = 0
var _level_add: int = 0
var _power: int = 0
var _power_add: int = 0
var _aura_effect_is_friendly: bool = false
var _aura_effect: BuffType = null

var _caster: Unit = null

@onready var _timer: Timer = $Timer


func _ready():
	_timer.one_shot = false
	_timer.wait_time = 0.2
	_timer.start()

# 	NOTE: supress "variable never used" warning 
	_aura_effect_is_friendly = _aura_effect_is_friendly


func _on_Timer_timeout():
	if _aura_effect == null:
		return

	var unit_list: Array[Unit] = Utils.get_units_in_range(_target_type, _caster.position, _aura_range)

	if !_target_self:
		unit_list.erase(_caster)

	for unit in unit_list:
		# NOTE: use 0.21 duration so that buff is refreshed
		# right before it expires
		_aura_effect.apply_custom_timed(_caster, unit, get_level(), 0.21)


func get_power() -> int:
	return _power + _caster.get_level() * _power_add


func get_level() -> int:
	return _level + _caster.get_level() * _level_add
