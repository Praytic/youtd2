class_name BuffRangeArea
extends Area2D

# BuffRangeArea wraps an Area2D  with circle shape. Used by
# Buff to implement the "unit comes in range" event.

signal unit_came_in_range(handler_object, handler_function, unit)

var _target_type: TargetType
var _handler_object: Node
var _handler_function: String


func _init():
	body_entered.connect(_on_body_entered)


func init(radius: float, target_type: TargetType, handler_object: Node, handler_function: String):
	Utils.circle_shape_set_radius($CollisionShape2D, radius)
	_target_type = target_type
	_handler_object = handler_object
	_handler_function = handler_function


func _on_body_entered(body: Node):
	if !body is Unit:
		return
	
	var unit: Unit = body as Unit

	if unit.is_invisible():
		return

	var target_match: bool = _target_type.match(unit)

	if target_match:
		unit_came_in_range.emit(_handler_object, _handler_function, unit)
