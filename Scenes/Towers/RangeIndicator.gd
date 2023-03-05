class_name RangeIndicator
extends Node2D

# Shows range of a tower by drawing a circle of pulsing dots.

@export var radius: float
@onready var texture: Texture2D = load("res://Resources/PulsingDot.tres")


func _draw():
	_draw_circle_arc(self.position, 0, 360, Color.AQUA)


func _draw_circle_arc(center, angle_from, angle_to, color):
	var nb_points = radius/20
	var points_arc = PackedVector2Array()
	
	for i in range(nb_points + 1):
		var angle_point = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	
	for index_point in range(nb_points):
		draw_texture(texture, points_arc[index_point] - texture.get_size() / 2, color)


func set_radius(value: float):
	radius = value
