class_name Selection extends Node2D

# Draws a circle to indicate unit being selected or unit
# being hovered by mouse

# NOTE: set this to change size of drawn circle
var visual_size: float = 10.0


func _ready():
	transform = Transform2D().scaled(Vector2(1, 0.5))


func _draw():
	draw_arc(Vector2.ZERO, visual_size, deg_to_rad(0), deg_to_rad(360), 100, Color.WHITE, 10, true)
