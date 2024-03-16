class_name RangeIndicator
extends Node2D

# Shows range of a tower by drawing a circle.


const POINT_COUNT: int = 100

@export var radius: float
@export var enable_floor_collisions: bool = true
@export var color: Color
@onready var _map = get_tree().get_root().get_node("GameScene/World/Map")

# NOTE: y_offset is used by TowerPreview to draw range
# indicator at an offset so that it's at same y coord as the
# tower sprite.
var y_offset: float = 0.0
var _prev_pos: Vector2 = Vector2.INF


#########################
###     Built-in      ###
#########################

func _draw():
	_draw_circle_arc(self.position, 0, 360)


# NOTE: redraw when position changes because depending on
# position, we need to draw different transparency sections.
# For towers, we never redraw because they don't move.
# For tower preview, we redraw as the mouse moves around.
func _process(_delta: float):
	var new_pos: Vector2 = global_position
	var pos_changed: bool = new_pos != _prev_pos
	_prev_pos = new_pos

	if pos_changed:
		queue_redraw()


#########################
###       Public      ###
#########################

func set_radius(radius_wc3: float):
	radius = Utils.to_pixels(radius_wc3)


#########################
###      Private      ###
#########################

func _draw_circle_arc(center: Vector2, angle_from: float, angle_to: float):
	var transparent_color: Color = Color(color).darkened(0.5)
	transparent_color.a = 0.2

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
	for i in range(POINT_COUNT):
		var current_angle: float = deg_to_rad(angle_from + i * (angle_to - angle_from) / POINT_COUNT)
		var point_top_down: Vector2 = center + Vector2(radius, 0).rotated(current_angle)
		var point_isometric: Vector2 = Isometric.top_down_vector_to_isometric(point_top_down) + Vector2(0, y_offset)
		
		var global_point_pos: Vector2 = point_isometric + global_position
		var pos_is_on_ground: bool = _map.pos_is_on_ground(global_point_pos)
		
		if pos_is_on_ground && !on_ground:
			on_ground_start_angle = prev_angle
			on_ground = true
		elif !pos_is_on_ground && on_ground:
			var on_ground_end_angle: float = current_angle
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
	var range_indicator: RangeIndicator = preload("res://Scenes/Towers/RangeIndicator.tscn").instantiate()
	return range_indicator
