class_name Creep
extends Unit


# TODO: implement armor

signal moved(delta)


# NOTE: order is important to be able to compare
enum Size {
	MASS,
	NORMAL,
	AIR,
	CHAMPION,
	BOSS,
	CHALLENGE_MASS,
	CHALLENGE_BOSS,
}

enum Category {
	UNDEAD,
	MAGIC,
	NATURE,
	ORC,
	HUMANOID,
}

const CREEP_HEALTH_MAX: float = 200.0
const MOVE_SPEED_MIN: float = 100.0
const MOVE_SPEED_MAX: float = 500.0
const DEFAULT_MOVE_SPEED: float = MOVE_SPEED_MAX
const SELECTION_SIZE: int = 64
const HEIGHT_TWEEN_FAST_FORWARD_DELTA: float = 100.0

var _path_curve: Curve2D : get = get_path_curve
var _size: Creep.Size : set = set_creep_size, get = get_creep_size
var _category: Creep.Category : set = set_category, get = get_category
var _armor_type: ArmorType.enm : set = set_armor_type, get = get_armor_type
var _current_path_index: int = 0
var movement_enabled: bool = true 
var _facing_angle: float = 0.0
var _height_tween: Tween = null

@onready var _visual = $Visual
@onready var _sprite = $Visual/Sprite2D
@onready var _health_bar = $Visual/HealthBar


#########################
### Code starts here  ###
#########################

func _ready():
	health_changed.connect(on_health_changed)


func _process(delta):
	if movement_enabled:
		_move(delta)

	var creep_animation: String = _get_creep_animation()
	_sprite.play(creep_animation)


#########################
###       Public      ###
#########################

func adjust_height(height: float, speed: float):
#	If a tween is already running, complete it instantly
#	before starting new one.
	if _height_tween != null:
		if _height_tween.is_running():
			_height_tween.custom_step(HEIGHT_TWEEN_FAST_FORWARD_DELTA)

		_height_tween.kill()
		_height_tween = null

	_height_tween = create_tween()

	var duration: float = abs(height / speed)

	_height_tween.tween_property(_visual, "position",
		Vector2(_visual.position.x, _visual.position.y - height),
		duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)


#########################
###      Private      ###
#########################

func _move(delta):
	var path_point: Vector2 = _path_curve.get_point_position(_current_path_index)
	position = position.move_toward(path_point, _get_move_speed() * delta)
	moved.emit(delta)
	
	var reached_path_point: bool = (position == path_point)

	var move_direction: Vector2 = path_point - position
	var move_angle: float = rad_to_deg(move_direction.angle())

#	NOTE: on path turns, the move angle becomes 0 for some
#	reason so don't update unit facing during that period
	if int(abs(move_angle)) > 0:
		set_unit_facing(move_angle)
	
	if reached_path_point:
		_current_path_index += 1

#		Delete creep once it has reached the end of the path
		var reached_end_of_path: bool = (_current_path_index >= _path_curve.get_point_count())

		if reached_end_of_path:
			queue_free()
			return


func _get_creep_animation() -> String:
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


func _get_move_speed() -> float:
	var base: float = DEFAULT_MOVE_SPEED
	var mod: float = get_prop_move_speed()
	var mod_absolute: float = get_prop_move_speed_absolute()
	var unclamped: float = base * mod + mod_absolute
	var limit_length: float = min(MOVE_SPEED_MAX, max(MOVE_SPEED_MIN, unclamped))

	return limit_length


#########################
###     Callbacks     ###
#########################

func on_health_changed():
	_health_bar.set_as_ratio(_health / get_overall_health())


#########################
### Setters / Getters ###
#########################


func get_selection_size():
	return SELECTION_SIZE


# TODO: Do creeps need IDs?
func get_id():
	return 1


func set_unit_facing(angle: float):
# 	NOTE: limit facing angle to (0, 360) range
	_facing_angle = int(angle + 360) % 360

	var animation: String = _get_creep_animation()
	_sprite.play(animation)


func get_unit_facing() -> float:
	return _facing_angle


func get_path_curve() -> Curve2D:
	return _path_curve

func set_creep_size(value: Creep.Size) -> void:
	_size = value

func get_creep_size() -> Creep.Size:
	return _size

func set_category(value: Creep.Category) -> void:
	_category = value

func get_category() -> int:
	return _category

func set_armor_type(value: ArmorType.enm) -> void:
	_armor_type = value

func get_armor_type() -> ArmorType.enm:
	return _armor_type

# NOTE: use this instead of regular Node2D.position for
# anything involving visual effects, so projectiles and spell
# effects.
func get_visual_position() -> Vector2:
	return _visual.global_position


func get_display_name() -> String:
	return "Generic Creep"


func set_path(path: Path2D):
	_path_curve = path.get_curve()
	position = _path_curve.get_point_position(0)
