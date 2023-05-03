class_name BuffRangeArea
extends Area2D

# BuffRangeArea wraps an Area2D  with circle shape. Used by
# Buff to implement the "unit comes in range" event.

signal unit_came_in_range(callable: Callable, unit: Unit)

var _target_type: TargetType
var _callable: Callable


func _init():
	body_entered.connect(_on_body_entered)


func init(radius: float, target_type: TargetType, callable: Callable):
	Utils.circle_polygon_set_radius($CollisionPolygon2D, radius)
	_target_type = target_type
	_callable = callable


func _on_body_entered(body: Node):
	if !body is Unit:
		return
	
	var unit: Unit = body as Unit

	if unit.is_invisible():
		return

	var target_match: bool = _target_type.match(unit)

	if target_match:
		unit_came_in_range.emit(_callable, unit)
