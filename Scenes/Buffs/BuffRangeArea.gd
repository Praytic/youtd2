class_name BuffRangeArea
extends Node2D

# BuffRangeArea emits a signal when a unit that matches the
# defined target type comes in range. Used by buffs to
# implement the "unit comes in range" event.

signal unit_came_in_range(handler: Callable, unit: Unit)

static var _buff_range_area_scene: PackedScene = preload("res://Scenes/Buffs/BuffRangeArea.tscn")

var _target_type: TargetType
var _handler: Callable
var _radius: float
var _prev_units_in_range: Array = []


static func make(radius: float, target_type: TargetType, handler: Callable) -> BuffRangeArea:
	var buff_range_area: BuffRangeArea = _buff_range_area_scene.instantiate()
	buff_range_area._radius = radius
	buff_range_area._target_type = target_type
	buff_range_area._handler = handler

	return buff_range_area


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
			unit_came_in_range.emit(_handler, unit)

	_prev_units_in_range = matching_units
