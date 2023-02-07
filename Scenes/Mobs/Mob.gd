class_name Mob
extends Unit

# TODO: is AIR part of Mob.Size? or should it be a separate
# enum IsAir { YES, NO }?

signal moved(delta)

enum Size {
	MASS,
	NORMAL,
	CHAMPION,
	BOSS,
}

enum Type {
	UNDEAD,
	MAGIC,
	NATURE,
	ORC,
	HUMANOID,
}

const MOB_HEALTH_MAX: float = 100.0
const MOB_MOVE_SPEED_MIN: float = 100.0
const MOB_MOVE_SPEED_MAX: float = 500.0

var _mob_move_speed: float
var _path_curve: Curve2D
var _current_path_index: int = 0
var _size: int = Size.NORMAL
var _type: int = Type.HUMANOID

onready var _sprite = $Sprite


func _ready():
	_mob_move_speed = MOB_MOVE_SPEED_MAX

	connect("damaged", self, "on_damaged")


func _process(delta):
	var path_point: Vector2 = _path_curve.get_point_position(_current_path_index)
	var move_speed: float = min(MOB_MOVE_SPEED_MAX, max(MOB_MOVE_SPEED_MIN, _mob_move_speed))
	position = position.move_toward(path_point, move_speed * delta)
	emit_signal("moved", delta)
	
	var reached_path_point: bool = (position == path_point)
	
	if reached_path_point:
		_current_path_index += 1

		#		Delete mob once it has reached the end of the path
		var reached_end_of_path: bool = (_current_path_index >= _path_curve.get_point_count())

		if reached_end_of_path:
			die()
			return
		
		var mob_animation: String = _get_mob_animation()
		_sprite.play(mob_animation)


func get_size() -> int:
	return _size


func get_type() -> int:
	return _type


func set_path(path: Path2D):
	_path_curve = path.curve
	position = _path_curve.get_point_position(0)


func on_damaged(_event: Event):
	$HealthBar.set_as_ratio(_health / MOB_HEALTH_MAX)


func _get_mob_animation() -> String:
	var path_point: Vector2 = _path_curve.get_point_position(_current_path_index)
	var move_direction: Vector2 = path_point - position
	var move_angle: float = rad2deg(move_direction.angle())

#	NOTE: the actual angles for 4-directional isometric movement are around
#   +- 27 degrees from x axis but checking for which quadrant the movement vector
#	falls into works just as well
	if 0 < move_angle && move_angle < 90:
		return "run_e"
	elif 90 < move_angle && move_angle < 180:
		return "run_s"
	elif -180 < move_angle && move_angle < -90:
		return "run_w"
	elif -90 < move_angle && move_angle < 0:
		return "run_n"
	else:
		return "stand"


func _modify_property(modification_type: int, value: float):
	match modification_type:
		Modification.Type.MOD_MOVE_SPEED:
			_mob_move_speed = _mob_move_speed * (1.0 + value)
		Modification.Type.MOD_MOVE_SPEED_ABSOLUTE:
			_mob_move_speed = _mob_move_speed + value
