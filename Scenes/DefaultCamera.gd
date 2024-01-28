extends Camera2D


# NOTE: camera has to handle game pause in a special way so
# that it's zoom is properly updated when interface scale is
# changed in settings menu. Camera's process mode is set to
# ALWAYS so that it ignores pause but then in _process() and
# _handle_input() it will return early if game is paused.
# This is so that player can't change camera zoom or move
# camera while game is paused.


signal camera_moved(shift_vector)
signal camera_zoomed(zoom_value)


@export var cam_move_speed_base: float = 1500.0
@export var zoom_min: float = 0.7
@export var zoom_max: float = 1.1
@export var zoom_sensitivity: float = 1.0
@export var mousewheel_zoom_speed: float = 0.4
@export var SLOW_SCROLL_MARGIN: float = 0.010
@export var FAST_SCROLL_MARGIN: float = 0.002
@export var SLOW_SCROLL_MULTIPLIER: float = 0.5


var _interface_size_factor: float = 1.0
var _zoom_multiplier: float = 1.0


#########################
###     Built-in      ###
#########################

func _ready():
	if OS.get_name() == "macOS":
		zoom_sensitivity = 0.1
	
	Settings.changed.connect(_on_settings_changed)
	_on_settings_changed()


func _physics_process(delta):
#	NOTE: perform this operation even during pause so that
#	camera reacts correctly to interface scale getting
#	changed in settings menu.
	zoom = Vector2.ONE * _interface_size_factor * _zoom_multiplier
	
	if get_tree().is_paused():
		return

	var mouse_scroll_is_enabled: bool = Settings.get_bool_setting(Settings.ENABLE_MOUSE_SCROLL)
	var speed_from_mouse: float = _get_cam_speed_from_setting(Settings.MOUSE_SCROLL)
	var speed_from_keyboard: float = _get_cam_speed_from_setting(Settings.KEYBOARD_SCROLL)

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var screen_size: Vector2 = get_viewport_rect().size

	var mouse_ratio: Vector2 = mouse_pos / screen_size

	var move_direction_from_mouse: Vector2 = Vector2.ZERO
	if mouse_ratio.x < SLOW_SCROLL_MARGIN:
		move_direction_from_mouse += Vector2.LEFT
	if mouse_ratio.x > 1.0 - SLOW_SCROLL_MARGIN:
		move_direction_from_mouse += Vector2.RIGHT
	if mouse_ratio.y < SLOW_SCROLL_MARGIN:
		move_direction_from_mouse += Vector2.UP
	if mouse_ratio.y > 1.0 - SLOW_SCROLL_MARGIN:
		move_direction_from_mouse += Vector2.DOWN
		
	var mouse_scroll_at_fast_speed: bool = false
	if mouse_ratio.x < FAST_SCROLL_MARGIN:
		mouse_scroll_at_fast_speed = true
	if mouse_ratio.y < FAST_SCROLL_MARGIN:
		mouse_scroll_at_fast_speed = true
	if mouse_ratio.y > 1.0 - FAST_SCROLL_MARGIN:
		mouse_scroll_at_fast_speed = true
	if mouse_ratio.x > 1.0 - FAST_SCROLL_MARGIN:
		mouse_scroll_at_fast_speed = true

	var move_direction_from_keyboard: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		move_direction_from_keyboard += Vector2.LEFT
	if Input.is_action_pressed("ui_right"):
		move_direction_from_keyboard += Vector2.RIGHT
	if Input.is_action_pressed("ui_up"):
		move_direction_from_keyboard += Vector2.UP
	if Input.is_action_pressed("ui_down"):
		move_direction_from_keyboard += Vector2.DOWN

	var move_direction: Vector2 = Vector2.ZERO
	var move_speed: float = 0.0
	if move_direction_from_keyboard != Vector2.ZERO:
		move_direction = move_direction_from_keyboard
		move_speed = speed_from_keyboard
	elif move_direction_from_mouse != Vector2.ZERO && mouse_scroll_is_enabled:
		move_direction = move_direction_from_mouse
		move_speed = speed_from_mouse

		if !mouse_scroll_at_fast_speed:
			move_speed *= SLOW_SCROLL_MULTIPLIER

#	NOTE: normalize direction vector so that camera moves at
#	the same speed in all directions
	move_direction = move_direction.normalized()

	if (move_direction != Vector2.ZERO):
		var zoom_ratio = sqrt(zoom.x)
		var shift_vector: Vector2 = move_direction * delta * move_speed * zoom_ratio
		position = get_screen_center_position() + shift_vector
		
		camera_moved.emit(shift_vector)


func _unhandled_input(event: InputEvent):
	if get_tree().is_paused():
		return

	var new_zoom_multiplier: float = _get_new_zoom_multiplier(event)
	var zoom_multiplier_changed: bool = new_zoom_multiplier != _zoom_multiplier

	if zoom_multiplier_changed:
		_zoom_multiplier = new_zoom_multiplier
		camera_zoomed.emit(_zoom_multiplier)


#########################
###      Private      ###
#########################

# Gets modified zoom multiplier after applying player input
func _get_new_zoom_multiplier(event: InputEvent) -> float:
	var zoom_change: float

	if event is InputEventMagnifyGesture && Config.enable_zoom_by_touchpad():
		zoom_change = -(event.factor - 1.0) * zoom_sensitivity
	elif event is InputEventMouseButton && Config.enable_zoom_by_mousewheel():
#		Make zoom change slower as the camera gets more zoomed in
		var slow_down_multiplier: float = _zoom_multiplier / zoom_max
		var zoom_change_direction: int
		match event.get_button_index():
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom_change_direction = -1
			MOUSE_BUTTON_WHEEL_UP:
				zoom_change_direction = 1
			_:
				zoom_change_direction = 0

		zoom_change = zoom_change_direction * mousewheel_zoom_speed * slow_down_multiplier
	else:
		zoom_change = 0.0

	var new_zoom: float = _zoom_multiplier + zoom_change
	new_zoom = clampf(new_zoom, zoom_min, zoom_max)

	return new_zoom


# NOTE: setting value is in range of [0.0, 1.0]
# Convert to actual speed.
func _get_cam_speed_from_setting(setting: String) -> float:
	var setting_value: float = Settings.get_setting(setting) as float
	var speed_ratio: float = 1.0 + 2.0 * setting_value
	var speed: float = cam_move_speed_base * speed_ratio

	return speed


func _get_viewport_scale_factor() -> float: 
	var factor = min(
		(float(get_viewport().size.x) / get_viewport().get_visible_rect().size.x),
		(float(get_viewport().size.y) / get_viewport().get_visible_rect().size.y))
	return factor


#########################
###     Callbacks     ###
#########################

# This function is needed because content_scale_factor of root Window
# affects all Nodes. So we need to readjust Camera2D to fit new viewport.
func _on_settings_changed():
	var interface_size: float = Settings.get_interface_size()
	_interface_size_factor = 1.0 / interface_size
