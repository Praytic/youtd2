class_name RangeIndicator
extends Node2D

# Shows range of a tower by drawing a circle of pulsing dots.

const TEXTURE_SCALE: float = 0.1

@export var radius: float
@onready var texture: Texture2D = load("res://Resources/PulsingDot.tres")
@onready var _map = get_tree().get_root().get_node("GameScene/Map")

var y_offset: float = 0.0


func _draw():
	_draw_circle_arc(self.position, 0, 360, Color.AQUA)


func _draw_circle_arc(center, angle_from, angle_to, color):
	var nb_points = radius/20
	var points_arc = PackedVector2Array()
	
	for i in range(nb_points + 1):
		var current_angle: float = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points)
		var point_top_down: Vector2 = center + Vector2(radius, 0).rotated(current_angle)
		var point_isometric: Vector2 = Isometric.top_down_vector_to_isometric(point_top_down) + Vector2(0, y_offset)
		points_arc.push_back(point_isometric)
	
#	NOTE: need to divide points by scale because scale
#	applies to positions as well but we want to only scale
#	the texture
	var transform_scale: Vector2 = Vector2(TEXTURE_SCALE, TEXTURE_SCALE)
	draw_set_transform(Vector2.ZERO, 0.0, transform_scale)
	
	for index_point in range(nb_points):
		var texture_pos: Vector2 = points_arc[index_point] / TEXTURE_SCALE
		if _map.get_layer_at_pos(points_arc[index_point] + global_position + texture.get_size() * TEXTURE_SCALE / 2) == 0:
			draw_texture(texture, texture_pos, color)


func set_radius(radius_wc3: float):
	radius = Utils.to_pixels(radius_wc3)
