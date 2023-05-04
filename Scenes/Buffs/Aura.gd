class_name Aura
extends Node2D

# Aura applies an aura effect(buff) to targets in range of
# caster. Should be created using AuraType.


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
var _target_list: Array = []


func _ready():
# 	NOTE: supress "variable never used" warning 
	_aura_effect_is_friendly = _aura_effect_is_friendly

	_caster.level_up.connect(_on_caster_level_up)


func get_power() -> int:
	return _power + _caster.get_level() * _power_add


func get_level() -> int:
	return _level + _caster.get_level() * _level_add


# NOTE: when caster levels up, re-apply aura effect. apply()
# will upgrade the aura effect.
func _on_caster_level_up(_event: Event):
	for target in _target_list:
		if !is_instance_valid(target):
			continue

		_aura_effect.apply_advanced(_caster, target, get_level(), get_power(), -1)


func _on_timer_timeout():
# 	Remove buff from units that have went out of range or
# 	became invisible
	var removed_target_list: Array = []
	
	for target in _target_list:
		if !is_instance_valid(target):
			removed_target_list.append(target)

			continue

		var distance: float = Isometric.vector_distance_to(global_position, target.position)
		var out_of_range: bool = distance > _aura_range

		if out_of_range || target.is_invisible():
			removed_target_list.append(target)

	for target in removed_target_list:
		_target_list.erase(target)

		if !is_instance_valid(target):
			continue

		var buff: Buff = target.get_buff_of_type(_aura_effect)

		if buff != null:
			buff._applied_by_aura_count -= 1

			var buff_not_applied_by_any_aura: bool = buff._applied_by_aura_count == 0

			if buff_not_applied_by_any_aura:
				buff.remove_buff()

# 	Apply buff to units in range
	var units_in_range: Array = Utils.get_units_in_range(_target_type, global_position, _aura_range)

	for unit in _target_list:
		units_in_range.erase(unit)

	for unit in units_in_range:
		if !_target_self && unit == self:
			continue

		_target_list.append(unit)
		
		var buff: Buff = _aura_effect.apply_advanced(_caster, unit, get_level(), get_power(), -1)
		buff._applied_by_aura_count += 1
