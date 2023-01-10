extends KinematicBody2D

class_name Mob

export var health: int = 10
export var mob_move_speed: int = 500


var last_position
var path_curve: Curve2D
var current_path_index: int = 0

onready var _sprite = $Sprite


func _ready():
	last_position = global_position


func _process(delta):
	var move_direction = last_position - global_position
	
	var path_point: Vector2 = path_curve.get_point_position(current_path_index)
	position = position.move_toward(path_point, mob_move_speed * delta)
	
	var reached_path_point: bool = (position == path_point)
	
	if reached_path_point:
		current_path_index += 1
		
#		Delete mob once it has reached the end of the path
		var reached_end_of_path: bool = (current_path_index >= path_curve.get_point_count())

		if reached_end_of_path:
			queue_free()

	if move_direction != Vector2.ZERO:
		var angle = (int(rad2deg(move_direction.angle_to(Vector2.ONE))) + 360) % 360
		print(angle)
		if angle >= 315 and angle <= 360 or angle >= 0 and angle < 45:
			print("Moving west")
			_sprite.play("run_w")
		elif angle >= 45 and angle < 135:
			print("Moving south")
			_sprite.play("run_s")
		elif angle >= 135 and angle < 225:
			print("Moving east")
			_sprite.play("run_e")
		elif angle >= 225 and angle < 315:
			print("Moving north")
			_sprite.play("run_n")
	else:
		_sprite.play("stand")

	last_position = global_position

func apply_damage(damage):
	health -= damage
	
	if health < 0:
		queue_free()


func set_path(path: Path2D):
	path_curve = path.curve
	position = path_curve.get_point_position(0)
