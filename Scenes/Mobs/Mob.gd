extends KinematicBody2D

class_name Mob


signal moved(delta)
signal dead


export var health_max: int = 100
export var health: int = 100
export var default_mob_move_speed: int = 500
var mob_move_speed: int
var buff_map: Dictionary


var path_curve: Curve2D
var current_path_index: int = 0


onready var _sprite = $Sprite


func _ready():
	mob_move_speed = default_mob_move_speed


func _process(delta):
	var path_point: Vector2 = path_curve.get_point_position(current_path_index)
	position = position.move_toward(path_point, mob_move_speed * delta)
	emit_signal("moved", delta)
	
	var reached_path_point: bool = (position == path_point)
	
	if reached_path_point:
		current_path_index += 1

		#		Delete mob once it has reached the end of the path
		var reached_end_of_path: bool = (current_path_index >= path_curve.get_point_count())

		if reached_end_of_path:
			die()
			return
		
		var mob_animation: String = get_mob_animation()
		_sprite.play(mob_animation)


func set_path(path: Path2D):
	path_curve = path.curve
	position = path_curve.get_point_position(0)


func get_mob_animation() -> String:
	var path_point: Vector2 = path_curve.get_point_position(current_path_index)
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

func die():
	emit_signal("dead")
	queue_free()


func apply_damage(damage: float):
	health -= damage

	$HealthBar.set_as_ratio(float(health) / float(health_max))

	if health < 0:
		die()


func apply_buff(buff):
	var buff_id: String = buff.get_id()

	var is_already_applied_to_target: bool = buff_map.has(buff_id)

	if is_already_applied_to_target:
		var current_buff = buff_map[buff_id]
		var should_override: bool = buff.power_level >= current_buff.power_level

		if should_override:
			current_buff.stop()
			apply_buff_internal(buff)
	else:
		apply_buff_internal(buff)


# NOTE: applies buff without any checks for overriding
func apply_buff_internal(buff):
	var buff_id: String = buff.get_id()
	print("buff_id=", buff_id)
	buff_map[buff_id] = buff
	add_child(buff)
	buff.on_applied_by_mob(self)

	buff.connect("expired", self, "on_buff_expired", [buff])


func on_buff_expired(buff):
	var buff_id: String = buff.get_id()
	buff_map.erase(buff_id)
