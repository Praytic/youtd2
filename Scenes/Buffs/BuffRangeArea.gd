class_name BuffRangeArea
extends Area2D

# BuffRangeArea wraps an Area2D  with circle shape. Used by
# Buff to implement the "unit comes in range" event.

signal unit_came_in_range(handler_function, unit)

var _target_type: int
var _handler_function: String


func _init():
	connect("body_entered", self, "_on_body_entered")


func init(radius: float, target_type: int, handler_function: String):
	Utils.circle_shape_set_radius($CollisionShape2D, radius)
	_target_type = target_type
	_handler_function = handler_function


func _on_body_entered(body: Node):
	var target_match: bool = _check_target_matc(body)

	if target_match:
		var unit: Unit = body as Unit
		emit_signal("unit_came_in_range", _handler_function, unit)


func _check_target_matc(body: Node) -> bool:
	var is_mob: bool = body is Mob
	var is_tower: bool = body is Tower

	match _target_type:
		Buff.TargetType.TOWER: return is_tower
		Buff.TargetType.MOB: return is_mob
		Buff.TargetType.ALL: return is_tower || is_mob

	return false
