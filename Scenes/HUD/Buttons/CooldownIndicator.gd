@tool
class_name CooldownIndicator extends Control

# Displays a rotating shadow polygon over a square area.
# When remaining cooldown ratio is 100% the shadow will
# cover the whole icon. As the remaining cooldown goes down,
# the shadow will rotate and fold until it goes away.


# NOTE: this angle determines the distance between progress
# points, in degrees
const ANGLE_STEP: int = 5


static var _progress_point_list: Array[Vector2]
static var _center_point: Vector2
static var _top_middle_point: Vector2
static var _top_left_point: Vector2
static var _top_right_point: Vector2
static var _bottom_left_point: Vector2
static var _bottom_right_point: Vector2

var _autocast: Autocast = null
var _progress_in_editor: float = 1.0


@export var overlay_color: Color = Color(0, 0, 0, 0.5)


#########################
###     Built-in      ###
#########################

# Setup points once inside static vars and reuse for all
# instances of CooldownIndicator.
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

# 	From top center to top left
	for angle in range(0, 45, ANGLE_STEP):
		var x: float = 0.5 - 0.5 * tan(deg_to_rad(angle))
		var y: float = 0
		var point: Vector2 = Vector2(x, y)
		_progress_point_list.append(point)

#	From top left to bottom left
	for angle in range(-45, 45, ANGLE_STEP):
		var x: float = 0
		var y: float = 0.5 + 0.5 * tan(deg_to_rad(angle))
		var point: Vector2 = Vector2(x, y)
		_progress_point_list.append(point)

# 	From bottom left to bottom right
	for angle in range(-45, 45, ANGLE_STEP):
		var x: float = 0.5 + 0.5 * tan(deg_to_rad(angle))
		var y: float = 1.0
		var point: Vector2 = Vector2(x, y)
		_progress_point_list.append(point)

#	From bottom right to top right
	for angle in range(45, -45, -ANGLE_STEP):
		var x: float = 1.0
		var y: float = 0.5 + 0.5 * tan(deg_to_rad(angle))
		var point: Vector2 = Vector2(x, y)
		_progress_point_list.append(point)

# 	From top right to top center
	for angle in range(-45, 0, ANGLE_STEP):
		var x: float = 0.5 - 0.5 * tan(deg_to_rad(angle))
		var y: float = 0
		var point: Vector2 = Vector2(x, y)
		_progress_point_list.append(point)


func _process(_delta: float):
	queue_redraw()


func _draw():
	var progress: float = _get_progress()
	var icon_size: float = size.x
	var point_list: PackedVector2Array = CooldownIndicator._generate_draw_points(progress, icon_size)

	if point_list.is_empty():
		return

	draw_colored_polygon(point_list, overlay_color)


#########################
###       Public      ###
#########################

func set_autocast(autocast: Autocast):
	_autocast = autocast


#########################
###      Private      ###
#########################

func _get_progress() -> float:
	if Engine.is_editor_hint():
		_progress_in_editor -= 0.005
		if _progress_in_editor < 0:
			_progress_in_editor = 1.0

		return _progress_in_editor
	else:
		if _autocast == null:
			return 0.0

		var cooldown: float = _autocast.get_cooldown()
		var remaining_cooldown: float = _autocast.get_remaining_cooldown()
		var progress: float = Utils.divide_safe(remaining_cooldown, cooldown)

		return progress


#########################
###       Static      ###
#########################

static func _generate_draw_points(progress: float, icon_size: float) -> PackedVector2Array:
	var current_progress_point: int = int(progress * (_progress_point_list.size() - 1))
	
	if current_progress_point < 3:
		return []

	var point_list: PackedVector2Array = []

	var progress_point: Vector2 = _progress_point_list[current_progress_point]
	point_list.append(progress_point)

#	Pick appropriate corner points, to complete the polygon
	if progress >= 7 / 8.0:
		point_list.append(_top_right_point)
	if progress >= 5 / 8.0:
		point_list.append(_bottom_right_point)
	if progress >= 3 / 8.0:
		point_list.append(_bottom_left_point)
	if progress >= 1 / 8.0:
		point_list.append(_top_left_point)
	
#	Top middle and center points are always drawn
	point_list.append(_top_middle_point)
	point_list.append(_center_point)

#	Scale all points so that they match the icon size
	for i in point_list.size():
		point_list[i] *= icon_size
	
	return point_list
