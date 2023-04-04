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


func _ready():
# 	NOTE: supress "variable never used" warning 
	_aura_effect_is_friendly = _aura_effect_is_friendly

	Utils.circle_polygon_set_radius($Area2D/CollisionPolygon2D, _aura_range)

	_caster.level_up.connect(_on_caster_level_up)


func get_power() -> int:
	return _power + _caster.get_level() * _power_add


func get_level() -> int:
	return _level + _caster.get_level() * _level_add


func _on_area_2d_body_entered(body: Node2D):
	if !_check_body_match(body):
		return

	var unit: Unit = body as Unit

	var buff: Buff = _aura_effect.apply_advanced(_caster, unit, get_level(), get_power(), -1)
	buff._applied_by_aura_count += 1


func _on_area_2d_body_exited(body: Node2D):
	if !_check_body_match(body):
		return

	var unit: Unit = body as Unit

	var buff: Buff = unit.get_buff_of_type(_aura_effect)

	if buff != null:
		buff._applied_by_aura_count -= 1

#		NOTE: remove buff only if it's not being applied by
#		other aura's on other casters. For example if a
#		target moves out of range of this aura but is still
#		in range of an aura on another caster, it should
#		still have the aura effect.
		if buff._applied_by_aura_count == 0:
			buff.remove_buff()


func _check_body_match(body: Node2D) -> bool:
	if !body is Unit:
		return false

	var unit: Unit = body as Unit

	if !_target_self && unit == self:
		return false

	var target_match: bool = _target_type.match(unit)

	return target_match


# NOTE: when caster levels up, re-apply aura effect. apply()
# will upgrade the aura effect.
func _on_caster_level_up(_event: Event):
	var unit_list: Array = Utils.get_units_in_range(_target_type, position, _aura_range)

	if !_target_self:
		unit_list.erase(self)

	for unit in unit_list:
		_aura_effect.apply_advanced(_caster, unit, get_level(), get_power(), -1)
