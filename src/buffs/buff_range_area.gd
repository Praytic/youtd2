class_name BuffRangeArea
extends Node2D

# BuffRangeArea emits a signal when a unit that matches the
# defined target type comes in range. Used by buffs to
# implement the "unit comes in range" event.

signal unit_came_in_range(handler: Callable, unit: Unit)


var _target_type: TargetType
var _handler: Callable
var _radius: float
var _buff: Buff
var _prev_units_in_range: Array = []


#########################
###     Callbacks     ###
#########################

func _on_manual_timer_timeout():
	var buffed_unit: Unit = _buff.get_buffed_unit()

	if buffed_unit == null:
		return

	var caster: Unit = _buff.get_caster()
	var buffed_unit_pos: Vector2 = buffed_unit.get_position_wc3_2d()
	var all_units_in_range: Array = Utils.get_units_in_range(caster, _target_type, buffed_unit_pos, _radius)

	var matching_units: Array = []

	for unit in all_units_in_range:
		var target_match: bool = _target_type.match(unit)
		var is_invisible: bool = unit.is_invisible()

		if target_match && !is_invisible:
			matching_units.append(unit)

	for unit in matching_units:
		var unit_just_came_in_range: bool = !_prev_units_in_range.has(unit)

		if unit_just_came_in_range:
			unit_came_in_range.emit(_handler, unit)

	_prev_units_in_range = matching_units


#########################
###       Static      ###
#########################

static func make(radius: float, target_type: TargetType, handler: Callable, buff: Buff) -> BuffRangeArea:
	var buff_range_area: BuffRangeArea = Preloads.buff_range_area_scene.instantiate()
	buff_range_area._radius = radius
	buff_range_area._target_type = target_type
	buff_range_area._handler = handler
	buff_range_area._buff = buff

	return buff_range_area
