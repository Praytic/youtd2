class_name BuffRangeArea
extends Area2D

# BuffRangeArea wraps an Area2D  with circle shape. Used by
# Buff to implement the "unit comes in range" event.

signal unit_came_in_range(handler_object, handler_function, unit)

var _target_type: TargetType
var _handler_object: Node
var _handler_function: String
var _emit_signal_in_process: bool
var _unit: Unit = null


func _init():
	body_entered.connect(_on_body_entered)


func init(radius: float, target_type: TargetType, handler_object: Node, handler_function: String):
	Utils.circle_polygon_set_radius($CollisionPolygon2D, radius)
	_target_type = target_type
	_handler_object = handler_object
	_handler_function = handler_function


func _process(_delta: float):
	if _emit_signal_in_process:
		_emit_signal_in_process = false
		unit_came_in_range.emit(_handler_object, _handler_function, _unit)


func _on_body_entered(body: Node):
	if !body is Unit:
		return
	
	var unit: Unit = body as Unit

	if unit.is_invisible():
		return

	var target_match: bool = _target_type.match(unit)

	if target_match:
		_emit_signal_in_process = true
		_unit = unit
