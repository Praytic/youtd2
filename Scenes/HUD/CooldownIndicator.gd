class_name CooldownIndicator extends Control

# Displays a rotating shadow over a square area. Use one of
# the add_to...() static f-ns to add cooldown indicator to a
# Control element.


var _base_point_list: Array[Vector2] = []
var _autocast: Autocast = null


static func add_to_button(autocast: Autocast, button: Button):
	var icon: Texture2D = button.icon
	var icon_size: float = icon.get_width()

	var button_stylebox: StyleBox = button.get_theme_stylebox("normal", "Button")
	var icon_offset: Vector2 = button_stylebox.get_offset()

	var cooldown_indicator: CooldownIndicator = _make_internal(autocast, icon_size, icon_offset)

	button.add_child(cooldown_indicator)


static func add_to_margin_container_and_texture_rect(autocast: Autocast, margin_container: MarginContainer, texture_rect: TextureRect):
	var icon: Texture2D = texture_rect.texture
	var icon_size: float = icon.get_width()
	
	var margin_left: float = margin_container.get_theme_constant("margin_left", "MarginContainer")
	var margin_top: float = margin_container.get_theme_constant("margin_top", "MarginContainer")
	var icon_offset: Vector2 = Vector2(margin_left, margin_top)

	var cooldown_indicator: CooldownIndicator = _make_internal(autocast, icon_size, icon_offset)

	margin_container.add_child(cooldown_indicator)


static func _make_internal(autocast: Autocast, icon_size: float, icon_offset: Vector2) -> CooldownIndicator:
	var cooldown_indicator_scene: PackedScene = load("res://Scenes/HUD/CooldownIndicator.tscn")
	var cooldown_indicator: CooldownIndicator = cooldown_indicator_scene.instantiate()

	cooldown_indicator._autocast = autocast
	cooldown_indicator._base_point_list = _generate_base_points(icon_size)
	cooldown_indicator.position = icon_offset

	return cooldown_indicator


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
