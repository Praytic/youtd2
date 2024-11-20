@tool
class_name TimeIndicator extends Control

# Displays a rotating shadow polygon over a square area,
# like a clock hand. Has two styles:
# - Expanding - shadow starts small and grows as elapsed
#   time increases until it covers the whole square.
# - Shrinking - shadow starts full, covering the whole
#   square, then shrinks until it goes away completely.


# NOTE: this angle determines the distance between progress
# points, in degrees
const ANGLE_STEP: int = 5

enum DrawStyle {
	EXPANDING,
	SHRINKING,
}


static var _progress_point_list: Array[Vector2]
static var _center_point: Vector2
static var _top_middle_point: Vector2
static var _top_left_point: Vector2
static var _top_right_point: Vector2
static var _bottom_left_point: Vector2
static var _bottom_right_point: Vector2

var _autocast: Autocast = null
var _progress_in_editor: float = 0.0
var _elapsed_progress: float = 0.0


@export var overlay_color: Color = Color8(0, 0, 0, 180)
@export var draw_style: TimeIndicator.DrawStyle = DrawStyle.SHRINKING


#########################
###     Built-in      ###
#########################

# Setup points once inside static vars and reuse for all
# instances of TimeIndicator.
# Pick points on a square, spaced out by angle from
# center. There is definitely a better way to do this but
# whatever.
static func _static_init():
	_center_point = Vector2(0.5, 0.5)
	_top_left_point = Vector2(0.0, 0.0)
	_top_middle_point = Vector2(0.5, 0.0)
	_top_right_point = Vector2(1.0, 0.0)
	_bottom_left_point = Vector2(0.0, 1.0)
	_bottom_right_point = Vector2(1.0, 1.0)

#	Generate "progress points", these points are spread
#	evenly along a square perimeter.

	_progress_point_list.append(_top_middle_point)

# 	From top center to top right
	for angle in range(0, 45, ANGLE_STEP):
		var x: float = 0.5 + 0.5 * tan(deg_to_rad(angle))
		var y: float = 0
		var point: Vector2 = Vector2(x, y)
		_progress_point_list.append(point)

#	From top right to bottom right
	for angle in range(-45, 45, ANGLE_STEP):
		var x: float = 1.0
		var y: float = 0.5 + 0.5 * tan(deg_to_rad(angle))
		var point: Vector2 = Vector2(x, y)
		_progress_point_list.append(point)

# 	From bottom right to bottom left
	for angle in range(-45, 45, ANGLE_STEP):
		var x: float = 0.5 - 0.5 * tan(deg_to_rad(angle))
		var y: float = 1.0
		var point: Vector2 = Vector2(x, y)
		_progress_point_list.append(point)

#	From bottom left to top left
	for angle in range(-45, 45, ANGLE_STEP):
		var x: float = 0.0
		var y: float = 0.5 - 0.5 * tan(deg_to_rad(angle))
		var point: Vector2 = Vector2(x, y)
		_progress_point_list.append(point)

# 	From top left to top center
	for angle in range(-45, 0, ANGLE_STEP):
		var x: float = 0.5 + 0.5 * tan(deg_to_rad(angle))
		var y: float = 0
		var point: Vector2 = Vector2(x, y)
		_progress_point_list.append(point)

	_progress_point_list.append(_top_middle_point)


func _process(_delta: float):
#	NOTE: simulate increasing progress for preview in editor
	if Engine.is_editor_hint():
		_progress_in_editor += 0.005
		if _progress_in_editor > 1.0:
			_progress_in_editor = 0.0

		_elapsed_progress = _progress_in_editor
	elif _autocast != null && is_instance_valid(_autocast):
#		Pull time values from autocast, if it's defined
		var overall_cooldown: float = _autocast.get_cooldown()
		var remaining_cooldown: float = _autocast.get_remaining_cooldown()
		var elapsed_cooldown: float = overall_cooldown - remaining_cooldown
		set_time_values(elapsed_cooldown, overall_cooldown)

	queue_redraw()


func _draw():
	var icon_size: float = size.x
	var point_list: PackedVector2Array = TimeIndicator._generate_draw_points(_elapsed_progress, icon_size, draw_style)

	if point_list.is_empty():
		return

	draw_colored_polygon(point_list, overlay_color)


#########################
###       Public      ###
#########################

# NOTE: need to clamp value because one time an autocast
# somehow had set elapsed time higher than overall time.
# Couldn't reproduce, try to look into it.
func set_time_values(elapsed_time: float, overall_time: float):
	_elapsed_progress = Utils.divide_safe(elapsed_time, overall_time)
	_elapsed_progress = clampf(_elapsed_progress, 0.0, 1.0)


# NOTE: you can pass an autocast to the indicator and the
# indicator will automatically pull cooldown values from it.
func set_autocast(autocast: Autocast):
	_autocast = autocast
	
#	NOTE: need to reset time values if there's no autocast
#	so that if item was changed, indicator doesn't keep
#	showing time value for previous item. Set item values to
#	1/1 (100% progress) so that no time indicator is drawn.
	if autocast == null:
		set_time_values(1.0, 1.0)


#########################
###       Static      ###
#########################

static func _generate_draw_points(progress: float, icon_size: float, style: TimeIndicator.DrawStyle) -> PackedVector2Array:
	var current_progress_point: int = floori(progress * (_progress_point_list.size() - 1))
	current_progress_point = clampi(current_progress_point, 0, _progress_point_list.size() - 1)
	var progress_point: Vector2 = _progress_point_list[current_progress_point]
	
	var point_list: PackedVector2Array = []

#	Pick appropriate corner points, to complete the polygon
	match style:
		TimeIndicator.DrawStyle.EXPANDING:
			point_list.append(_center_point)
			point_list.append(_top_middle_point)

			if progress >= 1 / 8.0:
				point_list.append(_top_right_point)
			if progress >= 3 / 8.0:
				point_list.append(_bottom_right_point)
			if progress >= 5 / 8.0:
				point_list.append(_bottom_left_point)
			if progress >= 7 / 8.0:
				point_list.append(_top_left_point)

			point_list.append(progress_point)
		TimeIndicator.DrawStyle.SHRINKING:
			var remaining_progress: float = 1.0 - progress
			
			point_list.append(_center_point)
			point_list.append(progress_point)

			if remaining_progress >= 7 / 8.0:
				point_list.append(_top_right_point)
			if remaining_progress >= 5 / 8.0:
				point_list.append(_bottom_right_point)
			if remaining_progress >= 3 / 8.0:
				point_list.append(_bottom_left_point)
			if remaining_progress >= 1 / 8.0:
				point_list.append(_top_left_point)
	
			point_list.append(_top_middle_point)

#	Scale all points so that they match the icon size
	for i in point_list.size():
		point_list[i] *= icon_size
	
	return point_list
