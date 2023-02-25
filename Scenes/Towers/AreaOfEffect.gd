class_name AreaOfEffect
extends Node2D


export(float) var radius
onready var texture: Texture = load("res://Resources/PulsingDot.tres")


func _draw():
	_draw_circle_arc(self.position, 0, 360, Color.aqua)


func _draw_circle_arc(center, angle_from, angle_to, color):
	var nb_points = radius/20
	var points_arc = PoolVector2Array()
	
	for i in range(nb_points + 1):
		var angle_point = deg2rad(angle_from + i * (angle_to - angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	
	for index_point in range(nb_points):
		draw_texture(texture, points_arc[index_point] - texture.get_size() / 2, color)


func set_radius(value: float):
	radius = value
