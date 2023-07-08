@tool
class_name CooldownIndicator extends Control

# Displays a rotating shadow over a square area. Use one of
# the add_to...() static f-ns to add cooldown indicator to a
# Control element.


var _base_point_list: Array[Vector2] = []
var _autocast: Autocast = null
var _progress_in_editor = 1.0
var _current_size: float = 0


func set_autocast(autocast: Autocast):
	_autocast = autocast


# Pick 360 points on a square, spaced out by angle from
# center. There is definitely a better way to do this but
# whatever.
static func _generate_base_points(icon_size: float) -> Array[Vector2]:
	var point_list: Array[Vector2] = []

	var icon_half_size: float = icon_size / 2

#	Center point
	point_list.append(Vector2(icon_half_size, icon_half_size))

# 	From top center to top left
	for angle in range(0, 45, 1):
		var x: float = icon_half_size - icon_half_size * tan(deg_to_rad(angle))
		var y: float = 0
		var point: Vector2 = Vector2(x, y)
		point_list.append(point)

#	From top left to bottom left
	for angle in range(-45, 45, 1):
		var x: float = 0
		var y: float = icon_half_size + icon_half_size * tan(deg_to_rad(angle))
		var point: Vector2 = Vector2(x, y)
		point_list.append(point)

# 	From bottom left to bottom right
	for angle in range(-45, 45, 1):
		var x: float = icon_half_size + icon_half_size * tan(deg_to_rad(angle))
		var y: float = icon_size
		var point: Vector2 = Vector2(x, y)
		point_list.append(point)

#	From bottom right to top right
	for angle in range(45, -45, -1):
		var x: float = icon_size
		var y: float = icon_half_size + icon_half_size * tan(deg_to_rad(angle))
		var point: Vector2 = Vector2(x, y)
		point_list.append(point)

# 	From top right to top center
	for angle in range(-45, 0, 1):
		var x: float = icon_half_size - icon_half_size * tan(deg_to_rad(angle))
		var y: float = 0
		var point: Vector2 = Vector2(x, y)
		point_list.append(point)
	
	return point_list


func _process(_delta: float):
	queue_redraw()


func _draw():
#	NOTE: check for size changes here so that size is
#	correct when this script runs in editor. If this script
#	ran only ingame, then doing this in _ready() would've
#	been enough.
	var icon_size: float = size.x
	if icon_size != _current_size:
		_base_point_list = _generate_base_points(icon_size)

	var progress: float
	
	if Engine.is_editor_hint():
		_progress_in_editor -= 0.01
		if _progress_in_editor < 0:
			_progress_in_editor = 1.0

		progress = _progress_in_editor
	else:
		if _autocast == null:
			return

		var cooldown: float = _autocast.get_cooldown()
		var remaining_cooldown: float = _autocast.get_remaining_cooldown()
		progress = remaining_cooldown / cooldown

	var point_list: PackedVector2Array = []
	var point_count: int = int(progress * _base_point_list.size())
	
	if point_count < 3:
		return

	for i in range(0, point_count):
		var point: Vector2 = _base_point_list[i]
		point_list.append(point)

	draw_colored_polygon(point_list, Color(0, 0, 0, 0.5))
