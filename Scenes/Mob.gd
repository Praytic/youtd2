extends PathFollow2D

class_name Mob

export var health: int = 10
export var mob_move_speed: int = 200


var last_position


onready var _sprite = $KinematicBody2D/Sprite


func _ready():
	last_position = global_position


func _process(delta):
	offset += delta * mob_move_speed
	var move_direction = last_position - global_position
	
	
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
	
	
#	Delete mob once it has reached the end of the path
	var reached_end_of_path: bool = (unit_offset >= 1.0)

	if reached_end_of_path:
		queue_free()
	last_position = global_position

func apply_damage(damage):
	health -= damage
	
	if health < 0:
		queue_free()

