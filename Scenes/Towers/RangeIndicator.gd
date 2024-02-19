class_name RangeIndicator
extends Node2D

# Shows range of a tower by drawing a circle of pulsing dots.

const TEXTURE_SCALE: float = 0.1

@export var radius: float
@export var enable_floor_collisions: bool = true
@export var texture_color: Color
@onready var texture: Texture2D = load("res://Resources/PulsingDot.tres")
@onready var _map = get_tree().get_root().get_node("GameScene/Map")

# NOTE: y_offset is used by TowerPreview to draw range
# indicator at an offset so that it's at same y coord as the
# tower sprite.
var y_offset: float = 0.0
var ignore_layer: bool = false


#########################
###     Built-in      ###
#########################

func _draw():
	_draw_circle_arc(self.position, 0, 360, texture_color)


#########################
###       Public      ###
#########################

func set_radius(radius_wc3: float):
	radius = Utils.to_pixels(radius_wc3)


#########################
###      Private      ###
#########################

func _draw_circle_arc(center, angle_from, angle_to, color):
	var transparent_color = Color(color).darkened(0.5)
	transparent_color.a = 0.2

	var nb_points = 100
	var points_arc = PackedVector2Array()
	var angles_tuple_array: Array = [] 
	var on_ground_start_angle: float = -1.0
	var on_ground = false
	var prev_angle: float = -1.0
	
	var transform_scale: Vector2 = Vector2(1.0, 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, transform_scale)
	
	if enable_floor_collisions:
		draw_arc(center + Vector2(0, y_offset) * 2, radius, deg_to_rad(angle_from), deg_to_rad(angle_to), 100, transparent_color, 5.0, true)
	else:
		draw_arc(center + Vector2(0, y_offset) * 2, radius, deg_to_rad(angle_from), deg_to_rad(angle_to), 100, color, 5.0, true)
		return
	
	# Calculate floor collisions for range indicator points.
	# Add points which are on the ground floor to the array.
	for i in range(nb_points):
		var current_angle: float = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points)
		var point_top_down: Vector2 = center + Vector2(radius, 0).rotated(current_angle)
		var point_isometric: Vector2 = Isometric.top_down_vector_to_isometric(point_top_down) + Vector2(0, y_offset)
		
		var global_point_pos: Vector2 = point_isometric + global_position
		var pos_is_on_ground: bool = _map.pos_is_on_ground(global_point_pos)
		
		if pos_is_on_ground && !on_ground:
			on_ground_start_angle = prev_angle
			on_ground = true
		elif !pos_is_on_ground && on_ground:
			var on_ground_end_angle = current_angle
			angles_tuple_array.append(Vector2(on_ground_start_angle, on_ground_end_angle))
			on_ground = false
		prev_angle = current_angle
	
	# If last ground point didn't have a closing pair point,
	# set it as a starting point for the first tuple.
	if on_ground && !angles_tuple_array.is_empty():
		angles_tuple_array[0].x = on_ground_start_angle - TAU
	
	# Only draw arcs which are on the ground floor, because previously
	# we already draw the whole circle with transparent color.
	for angles_tuple in angles_tuple_array:
		draw_arc(center + Vector2(0, y_offset) * 2, radius, angles_tuple.y, angles_tuple.x, 100, color, 5.0, true)


#########################
###       Static      ###
#########################

static func make() -> RangeIndicator:
	var range_indicator: RangeIndicator = Globals.range_indicator_scene.instantiate()
	return range_indicator
