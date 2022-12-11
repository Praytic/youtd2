extends Tower

class_name RotatingTower

var initialRotation

func _ready():
	initialRotation = get_node("Gun").rotation
	
func _physics_process(delta):
	var gun = get_node("Gun")
	var angle = gun.get_angle_to(get_global_mouse_position()) + initialRotation
	gun.rotate(angle)
