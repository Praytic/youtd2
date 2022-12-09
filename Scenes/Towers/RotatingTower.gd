extends Node2D

class_name RotatingTower

var initialRotation
var areaOfEffect: AreaOfEffect

func _init(radius: float, resolution: float):
	areaOfEffect = AreaOfEffect.new(radius, resolution)

func _ready():
	initialRotation = get_node("Gun").rotation
	print(self.position)
	areaOfEffect.position = self.position
	areaOfEffect.sprite.position = self.position
	add_child(areaOfEffect)

func _physics_process(delta):
	var gun = get_node("Gun")
	var angle = gun.get_angle_to(get_global_mouse_position()) + initialRotation
	gun.rotate(angle)
