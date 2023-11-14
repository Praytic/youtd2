extends Camera2D

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


func _ready():
	if OS.get_name() == "macOS":
		zoom_sensitivity = 0.1


func _physics_process(delta):
	var mouse_scroll_is_enabled: bool = Settings.get_bool_setting(Settings.ENABLE_MOUSE_SCROLL)
	var speed_from_mouse: float = _get_cam_speed_from_setting(Settings.MOUSE_SCROLL)
	var speed_from_keyboard: float = _get_cam_speed_from_setting(Settings.KEYBOARD_SCROLL)

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var screen_size: Vector2 = get_viewport_rect().size

	var mouse_ratio: Vector2 = mouse_pos / screen_size

	var move_direction_from_mouse: Vector2 = Vector2.ZERO
	if mouse_ratio.x < SLOW_SCROLL_MARGIN:
		move_direction_from_mouse.x += -1.0
	if mouse_ratio.x > 1.0 - SLOW_SCROLL_MARGIN:
		move_direction_from_mouse.x += 1.0
	if mouse_ratio.y < SLOW_SCROLL_MARGIN:
		move_direction_from_mouse.y += -1.0
	if mouse_ratio.y > 1.0 - SLOW_SCROLL_MARGIN:
		move_direction_from_mouse.y += 1.0
		
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
		move_direction_from_keyboard.x += -1.0
	if Input.is_action_pressed("ui_right"):
		move_direction_from_keyboard.x += 1.0
	if Input.is_action_pressed("ui_up"):
		move_direction_from_keyboard.y += -1.0
	if Input.is_action_pressed("ui_down"):
		move_direction_from_keyboard.y += 1.0

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
	_zoom(event)


# NOTE: this will be called by CameraZoomArea
func _zoom(event):
	var new_zoom = zoom.x

	if event is InputEventMagnifyGesture && Config.enable_zoom_by_touchpad():
		var zoom_amount = -(event.factor - 1.0) * zoom_sensitivity
		new_zoom = zoom.y + zoom_amount
	elif event is InputEventMouseButton && Config.enable_zoom_by_mousewheel():
#		Make zoom change slower as the camera gets more zoomed in
		var slow_down_multiplier = zoom.x / zoom_max
		var zoom_change = mousewheel_zoom_speed * slow_down_multiplier
		
		match event.get_button_index():
			MOUSE_BUTTON_WHEEL_DOWN:
				new_zoom += -zoom_change
			MOUSE_BUTTON_WHEEL_UP:
				new_zoom += zoom_change
			_:
				return
	else:
		return
	
	new_zoom = clampf(new_zoom, zoom_min, zoom_max)
	zoom = Vector2(new_zoom, new_zoom)
	
	camera_zoomed.emit(zoom)


# NOTE: setting value is in range of [0.0, 1.0]
# Convert to actual speed.
func _get_cam_speed_from_setting(setting: String) -> float:
	var setting_value: float = Settings.get_setting(setting) as float
	var speed_ratio: float = 1.0 + 2.0 * setting_value
	var speed: float = cam_move_speed_base * speed_ratio

	return speed
