extends Tower

class_name RotatingTower

export(float) var radius

var initialRotation
var aoe: AreaOfEffect

func _ready():
	initialRotation = get_node("Gun").rotation
	aoe = AreaOfEffect.new(radius)
	aoe.position = Vector2(size, size) / 2
	add_child(aoe)

func _physics_process(delta):
	var gun = get_node("Gun")
	var angle = gun.get_angle_to(get_global_mouse_position()) + initialRotation
	gun.rotate(angle)
