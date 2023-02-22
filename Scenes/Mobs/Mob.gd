class_name Mob
extends Unit


# TODO: implement armor


signal moved(delta)

enum MobProperty {
	ARMOR,
	EXP_GRANTED,
}

# NOTE: order is important to be able to compare
enum Size {
	MASS,
	NORMAL,
	AIR,
	CHAMPION,
	BOSS,
	CHALLENGE,
}

enum Type {
	UNDEAD,
	MAGIC,
	NATURE,
	ORC,
	HUMANOID,
}

const _mob_mod_to_property_map: Dictionary = {
	Modification.Type.MOD_ARMOR: MobProperty.ARMOR,
	Modification.Type.MOD_ARMOR_PERC: MobProperty.ARMOR,
	Modification.Type.MOD_EXP_GRANTED: MobProperty.EXP_GRANTED,
}

const MOB_HEALTH_MAX: float = 100.0

var _path_curve: Curve2D
var _current_path_index: int = 0
var _size: int = Size.NORMAL
var _type: int = Type.HUMANOID
var movement_enabled: bool = true 
var _mob_properties: Dictionary = {
	MobProperty.ARMOR: 0.0,
	MobProperty.EXP_GRANTED: 0.0,
}
var _facing_angle: float = 0.0


onready var _visual = $Visual
onready var _sprite = $Visual/Sprite
onready var _health_bar = $Visual/HealthBar
onready var _height_tween = $HeightTween


func _ready():
	connect("damaged", self, "on_damaged")


func _process(delta):
	if movement_enabled:
		_move(delta)

	var mob_animation: String = _get_mob_animation()
	_sprite.play(mob_animation)


func _move(delta):
	var path_point: Vector2 = _path_curve.get_point_position(_current_path_index)
	position = position.move_toward(path_point, get_move_speed() * delta)
	emit_signal("moved", delta)
	
	var reached_path_point: bool = (position == path_point)

	var move_direction: Vector2 = path_point - position
	var move_angle: float = rad2deg(move_direction.angle())

#	NOTE: on path turns, the move angle becomes 0 for some
#	reason so don't update unit facing during that period
	if int(move_angle) > 0:
		set_unit_facing(move_angle)
	
	if reached_path_point:
		_current_path_index += 1

#		Delete mob once it has reached the end of the path
		var reached_end_of_path: bool = (_current_path_index >= _path_curve.get_point_count())

		if reached_end_of_path:
			queue_free()
			return


func set_unit_facing(angle: float):
# 	NOTE: limit facing angle to (0, 360) range
	_facing_angle = int(angle + 360) % 360

	var animation: String = _get_mob_animation()
	_sprite.play(animation)


func get_unit_facing() -> float:
	return _facing_angle


func get_size() -> int:
	return _size


func get_type() -> int:
	return _type


# NOTE: use this instead of regular Node2D.position for
# anything involving visual effects, so projectiles and spell
# effects.
func get_visual_position() -> Vector2:
	return _visual.global_position


func set_path(path: Path2D):
	_path_curve = path.curve
	position = _path_curve.get_point_position(0)


func on_damaged(_event: Event):
	_health_bar.set_as_ratio(_health / MOB_HEALTH_MAX)


func adjust_height(height: float, speed: float):
#	NOTE: stop and clear tween in case it's already running
	_height_tween.stop_all()
	_height_tween.remove_all()

	var duration: float = height / speed

	_height_tween.interpolate_property(_visual, "position",
		_visual.position,
		Vector2(_visual.position.x, _visual.position.y - height),
		duration, Tween.TRANS_LINEAR, Tween.EASE_OUT)

	_height_tween.start()


func _get_mob_animation() -> String:
#	NOTE: the actual angles for 4-directional isometric movement are around
#   +- 27 degrees from x axis but checking for which quadrant the movement vector
#	falls into works just as well
	if 0 <= _facing_angle && _facing_angle < 90:
		return "run_e"
	elif 90 <= _facing_angle && _facing_angle < 180:
		return "run_s"
	elif 180 <= _facing_angle && _facing_angle < 270:
		return "run_w"
	elif 270 <= _facing_angle && _facing_angle <= 360:
		return "run_n"
	else:
		return "stand"


func _modify_property_subclass(modification_type: int, modification_value: float, modify_direction: int):
	_modify_property_general(_mob_properties, _mob_mod_to_property_map, modification_type, modification_value, modify_direction)
