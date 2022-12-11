extends PathFollow2D

class_name Mob

export var health: int = 10
export var mob_move_speed: int = 200

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func _process(delta):
	offset += delta * mob_move_speed

#	Delete mob once it has reached the end of the path
	var reached_end_of_path: bool = (unit_offset >= 1.0)

	if reached_end_of_path:
		queue_free()


func apply_damage(damage):
	health -= damage
	print("mob was shot, current hp:", health)
	
	if health < 0:
		print("mob is dead!")
		queue_free()
	
