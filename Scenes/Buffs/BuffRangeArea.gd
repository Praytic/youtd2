class_name BuffRangeArea
extends Node2D

# BuffRangeArea emits a signal when a unit that matches the
# defined target type comes in range. Used by buffs to
# implement the "unit comes in range" event.

signal unit_came_in_range(callable: Callable, unit: Unit)

var _target_type: TargetType
var _callable: Callable
var _radius: float
var _prev_units_in_range: Array = []


func init(radius: float, target_type: TargetType, callable: Callable):
	_radius = radius
	_target_type = target_type
	_callable = callable


func _on_timer_timeout():
	var all_units_in_range: Array = Utils.get_units_in_range(_target_type, global_position, _radius)

	var matching_units: Array = []

	for unit in all_units_in_range:
		var target_match: bool = _target_type.match(unit)
		var is_invisible: bool = unit.is_invisible()

		if target_match && !is_invisible:
			matching_units.append(unit)

	for unit in matching_units:
		var unit_just_came_in_range: bool = !_prev_units_in_range.has(unit)

		if unit_just_came_in_range:
			unit_came_in_range.emit(_callable, unit)

	_prev_units_in_range = matching_units
