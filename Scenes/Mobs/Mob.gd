class_name Mob
extends Unit


# TODO: implement armor


signal moved(delta)

enum MobProperty {
	ARMOR,
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

const _mob_add_mod_map: Dictionary = {
	Modification.Type.MOD_ARMOR: MobProperty.ARMOR
}
const _mob_percent_mod_map: Dictionary = {
	Modification.Type.MOD_ARMOR_PERC: MobProperty.ARMOR
}

const MOB_HEALTH_MAX: float = 100.0

var _path_curve: Curve2D
var _current_path_index: int = 0
var _size: int = Size.NORMAL
var _type: int = Type.HUMANOID
var _mob_properties: Dictionary = {
	MobProperty.ARMOR: 0.0,
}

onready var _sprite = $Sprite


func _ready():
	connect("damaged", self, "on_damaged")


func _process(delta):
	var path_point: Vector2 = _path_curve.get_point_position(_current_path_index)
	position = position.move_toward(path_point, get_move_speed() * delta)
	emit_signal("moved", delta)
	
	var reached_path_point: bool = (position == path_point)
	
	if reached_path_point:
		_current_path_index += 1

		#		Delete mob once it has reached the end of the path
		var reached_end_of_path: bool = (_current_path_index >= _path_curve.get_point_count())

		if reached_end_of_path:
			queue_free()
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

func _modify_property(modification_type: int, modification_value: float):
	_modify_property_general(_mob_properties, _mob_add_mod_map, _mob_percent_mod_map, modification_type, modification_value)
