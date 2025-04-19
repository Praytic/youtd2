class_name CameraController extends Node


# Controls camera movement and zoom level based on player input.


signal camera_moved(shift_vector)
signal camera_zoomed(zoom_value)


const MOVE_SPEED_BASE: float = 1500.0
const ZOOM_MIN: float = 0.5
const ZOOM_MAX: float = 1.1
const ZOOM_SPEED_FOR_TOUCHPAD_WINDOWS: float = 1.0
const ZOOM_SPEED_FOR_TOUCHPAD_MAC: float = 0.1
const ZOOM_SPEED_FOR_MOUSEWHEEL: float = 0.2
const SLOW_SCROLL_MARGIN: float = 0.010
const FAST_SCROLL_MARGIN: float = 0.002
const SLOW_SCROLL_MULTIPLIER: float = 0.5


var _current_zoom_value: float = 1.0
var _drag_origin: Vector2 = Vector2.INF
var _keyboard_enabled: bool = true
var _any_input_enabled: bool = true
var _zoom_speed_for_touchpad: float

@export var _camera: Camera2D


#########################
###     Built-in      ###
#########################

func _ready():
	if OS.get_name() == "macOS":
		_zoom_speed_for_touchpad = ZOOM_SPEED_FOR_TOUCHPAD_MAC
	else:
		_zoom_speed_for_touchpad = ZOOM_SPEED_FOR_TOUCHPAD_WINDOWS


func _process(delta):
	if !_any_input_enabled:
		return
	
	var game_window: Window = get_window()
	var game_has_focus: bool = game_window.has_focus()
	var mouse_scroll_is_enabled: bool = Settings.get_bool_setting(Settings.ENABLE_MOUSE_SCROLL)
	var should_do_mouse_scroll: bool = mouse_scroll_is_enabled && game_has_focus

	var speed_from_mouse: float = _get_cam_speed_from_setting(Settings.MOUSE_SCROLL)
	var speed_from_keyboard: float = _get_cam_speed_from_setting(Settings.KEYBOARD_SCROLL)

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var screen_size: Vector2 = _camera.get_viewport_rect().size

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
	
	if !_keyboard_enabled:
		move_direction_from_keyboard = Vector2.ZERO

#	NOTE: keep different ways of moving the camera
#	exclusive. Do not allow moving by keyboard and moving by
#	scroll at the same time.
	var move_direction: Vector2 = Vector2.ZERO
	var move_speed: float = 0.0
	if move_direction_from_keyboard != Vector2.ZERO:
		move_direction = move_direction_from_keyboard
		move_speed = speed_from_keyboard
	elif move_direction_from_mouse != Vector2.ZERO && should_do_mouse_scroll:
		move_direction = move_direction_from_mouse
		move_speed = speed_from_mouse

		if !mouse_scroll_at_fast_speed:
			move_speed *= SLOW_SCROLL_MULTIPLIER

#	NOTE: normalize direction vector so that camera moves at
#	the same speed in all directions
	move_direction = move_direction.normalized()
	
	var current_mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var drag_started: bool = Input.is_action_just_pressed("middle_click")
	var drag_in_progress: bool = Input.is_action_pressed("middle_click")
	
#	When drag starts, remember position which was clicked.
	if drag_started:
		_drag_origin = current_mouse_pos
	
#	While dragging, move the camera based on offset between
#	drag origin and current mouse position. Constantly
#	update drag origin so that new offsets can be
#	recalculated.
	var move_offset_from_drag: Vector2 = Vector2.ZERO
	if drag_in_progress && current_mouse_pos != _drag_origin:
		move_offset_from_drag = _drag_origin - current_mouse_pos
		_drag_origin = current_mouse_pos

#	NOTE: keep different ways of moving the camera
#	exclusive. Do not allow moving by keyboard/scroll during
#	drag.
	if drag_in_progress:
		_camera.position = _camera.get_screen_center_position() + move_offset_from_drag
	elif move_direction != Vector2.ZERO:
		var zoom_ratio = sqrt(_camera.zoom.x)
		var shift_vector: Vector2 = move_direction * delta * move_speed * zoom_ratio
		_camera.position = _camera.get_screen_center_position() + shift_vector
		
		camera_moved.emit(shift_vector)


# NOTE: player inputs modify zoom_multiplier variable
# instead of directly modifying zoom because zoom needs to
# also be divided by interface size. See update_zoom().
func _unhandled_input(event: InputEvent):
	if !_any_input_enabled:
		return
	
	var new_zoom_value: float = _calculate_new_zoom_value(event)
	var zoom_multiplier_changed: bool = new_zoom_value != _current_zoom_value

	if zoom_multiplier_changed:
		_current_zoom_value = new_zoom_value
		camera_zoomed.emit(_current_zoom_value)
		update_zoom()


#########################
###       Public      ###
#########################

func set_camera_limits(camera_limits_polygon: Polygon2D):
	var camera_limits_rect: Rect2 = Utils.get_polygon_bounding_box(camera_limits_polygon)
	_camera.limit_bottom = int(camera_limits_rect.end.y)
	_camera.limit_top = int(camera_limits_rect.position.y)
	_camera.limit_left = int(camera_limits_rect.position.x)
	_camera.limit_right = int(camera_limits_rect.end.x)


# Enables/disables moving camera with keyboard
func set_keyboard_enabled(value: bool):
	_keyboard_enabled = value


# Enables/disables performing any input on camera
func set_any_input_enabled(value: bool):
	_any_input_enabled = value


# NOTE: need to divide zoom by interface size because
# interface size is implemented by changing Window's
# content_scale_factor, which also affects how camera
# renders.
func update_zoom():
	var interface_size: float = Settings.get_interface_size()
	_camera.zoom = Vector2.ONE * _current_zoom_value / interface_size


#########################
###      Private      ###
#########################

# Gets modified zoom multiplier after applying player input
func _calculate_new_zoom_value(event: InputEvent) -> float:
	var zoom_change: float

	if event is InputEventMagnifyGesture && Config.enable_zoom_by_touchpad():
		zoom_change = -(event.factor - 1.0) * _zoom_speed_for_touchpad
	elif event is InputEventMouseButton && Config.enable_zoom_by_mousewheel():
#		Make zoom change slower as the camera gets more zoomed in
		var slow_down_multiplier: float = _current_zoom_value / ZOOM_MAX
		var zoom_change_direction: int
		match event.get_button_index():
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom_change_direction = -1
			MOUSE_BUTTON_WHEEL_UP:
				zoom_change_direction = 1
			_:
				zoom_change_direction = 0

		zoom_change = zoom_change_direction * ZOOM_SPEED_FOR_MOUSEWHEEL * slow_down_multiplier
	else:
		zoom_change = 0.0

	var new_zoom: float = _current_zoom_value + zoom_change
	new_zoom = clampf(new_zoom, ZOOM_MIN, ZOOM_MAX)

	return new_zoom


# NOTE: setting value is in range of [0.0, 1.0]
# Convert to actual speed.
func _get_cam_speed_from_setting(setting: String) -> float:
	var setting_value: float = Settings.get_setting(setting) as float
	var speed_ratio: float = 1.0 + 2.0 * setting_value
	var speed: float = MOVE_SPEED_BASE * speed_ratio

#	NOTE: this is a hackfix to make moving camera at min
#	zoom (zoomed out fully) not that slow.
	if _current_zoom_value == ZOOM_MIN:
		speed *= 3

	return speed


func _get_viewport_scale_factor() -> float: 
	var factor = min(
		(float(get_viewport().size.x) / get_viewport().get_visible_rect().size.x),
		(float(get_viewport().size.y) / get_viewport().get_visible_rect().size.y))
	
	return factor
