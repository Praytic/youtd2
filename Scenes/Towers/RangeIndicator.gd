class_name RangeIndicator
extends Node2D

# Shows range of a tower by drawing a circle of pulsing dots.

const TEXTURE_SCALE: float = 0.1

@export var radius: float
@export var draw_transparently_on_floor2: bool
@export var texture_color: Color
@onready var texture: Texture2D = load("res://Resources/PulsingDot.tres")
@onready var _map = get_tree().get_root().get_node("GameScene/Map")

# NOTE: y_offset is used by TowerPreview to draw range
# indicator at an offset so that it's at same y coord as the
# tower sprite.
var y_offset: float = 0.0
var ignore_layer: bool = false


static func make() -> RangeIndicator:
	var range_indicator: RangeIndicator = Globals.range_indicator_scene.instantiate()

	return range_indicator


func _draw():
	_draw_circle_arc(self.position, 0, 360, texture_color)


func _draw_circle_arc(center, angle_from, angle_to, color):
	var transparent_color = Color(color).darkened(0.5)
	transparent_color.a = 0.2

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

#	NOTE: need to subtract half texture size from point
#	position because draw_texture() uses top-left corner of
#	texture as origin.
	for index_point in range(nb_points):
		var texture_pos: Vector2 = points_arc[index_point] / TEXTURE_SCALE - texture.get_size() / 2
		var global_point_pos: Vector2 = points_arc[index_point] + global_position
		var pos_is_on_ground: bool = _map.pos_is_on_ground(global_point_pos)

		var color_at_pos: Color
		if draw_transparently_on_floor2:
			if pos_is_on_ground:
				color_at_pos = color
			else:
				color_at_pos = transparent_color
		else:
			color_at_pos = color

		draw_texture(texture, texture_pos, color_at_pos)


func set_radius(radius_wc3: float):
	radius = Utils.to_pixels(radius_wc3)
