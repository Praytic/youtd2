tool
extends Node2D

var radius: float
var resolution: float

func _init(radius: float, position: Vector2):
	var aoe_sprite = Sprite.new()
	aoe_sprite.texture = load("res://Resources/PulsingDot.tres")
	self.radius = radius
	self.resolution = resolution
