class_name CooldownIndicator extends Control

# Displays a rotating shadow over a square area. Add as
# child to a button and set target autocast using
# set_autocast().


var _icon_size: float
var _icon_half_size: float
var _base_point_list: Array[Vector2] = []
var _autocast: Autocast = null


func _ready():
	var button: Button = get_parent()
	var icon: Texture2D = button.icon
	
	if icon == null:
		push_error("Attached CooldownIndicator to a button without icon!")

		return

	_icon_size = icon.get_width()
	_icon_half_size = _icon_size / 2

#	Pick 360 points on the square, spaced out by angle from
#	center. There is definitely a better way to do this but
#	whatever.

#	Center point
	_base_point_list.append(Vector2(_icon_half_size, _icon_half_size))

# 	From top center to top left
	for angle in range(0, 45, 1):
		var x: float = _icon_half_size - _icon_half_size * tan(deg_to_rad(angle))
		var y: float = 0
		var point: Vector2 = Vector2(x, y)
		_base_point_list.append(point)

#	From top left to bottom left
	for angle in range(-45, 45, 1):
		var x: float = 0
		var y: float = _icon_half_size + _icon_half_size * tan(deg_to_rad(angle))
		var point: Vector2 = Vector2(x, y)
		_base_point_list.append(point)

# 	From bottom left to bottom right
	for angle in range(-45, 45, 1):
		var x: float = _icon_half_size + _icon_half_size * tan(deg_to_rad(angle))
		var y: float = _icon_size
		var point: Vector2 = Vector2(x, y)
		_base_point_list.append(point)

#	From bottom right to top right
	for angle in range(45, -45, -1):
		var x: float = _icon_size
		var y: float = _icon_half_size + _icon_half_size * tan(deg_to_rad(angle))
		var point: Vector2 = Vector2(x, y)
		_base_point_list.append(point)

# 	From top right to top center
	for angle in range(-45, 0, 1):
		var x: float = _icon_half_size - _icon_half_size * tan(deg_to_rad(angle))
		var y: float = 0
		var point: Vector2 = Vector2(x, y)
		_base_point_list.append(point)
	
#	NOTE: button's icon is drawn at an offset which is
#	determined by the theme. Offset all points so that the
#	indicator is drawn on top of the icon.
	var button_stylebox: StyleBox = button.get_theme_stylebox("normal", "Button")
	var button_icon_offset: Vector2 = button_stylebox.get_offset()
	
	for i in range(0, _base_point_list.size()):
		_base_point_list[i] = _base_point_list[i] + button_icon_offset


func _process(_delta: float):
	queue_redraw()


func _draw():
	var cooldown: float = _autocast.get_cooldown()
	var remaining_cooldown: float = _autocast.get_remaining_cooldown()
	var progress: float = remaining_cooldown / cooldown

	var point_list: PackedVector2Array = []
	var point_count: int = int(progress * _base_point_list.size())
	
	if point_count < 3:
		return

	for i in range(0, point_count):
		var point: Vector2 = _base_point_list[i]
		point_list.append(point)

	draw_colored_polygon(point_list, Color(0, 0, 0, 0.5))


func set_autocast(autocast: Autocast):
	_autocast = autocast
