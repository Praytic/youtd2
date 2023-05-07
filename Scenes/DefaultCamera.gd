extends Camera2D

signal camera_moved(shift_vector)
signal camera_zoomed(zoom_value)

@export var cam_move_speed: float = 2000.0
@export var maximum_zoom_in: float = 0.4
@export var minimum_zoom_out: float = 1.0
@export var zoom_sensitivity: float = 1.0
@export var mousewheel_zoom_speed: float = 0.4


func _ready():
	if OS.get_name() == "macOS":
		zoom_sensitivity = 0.1
	


func _physics_process(delta):
	var move_direction: Vector2 = Vector2.ZERO
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var screen_size: Vector2 = get_viewport_rect().size

	if Input.is_action_pressed("ui_left") or (mouse_pos.x / screen_size.x) < 0.05:
		move_direction.x += -1.0
	if Input.is_action_pressed("ui_right") or (mouse_pos.x / screen_size.x) > 0.95:
		move_direction.x += 1.0
	if Input.is_action_pressed("ui_up") or (mouse_pos.y / screen_size.y) < 0.04:
		move_direction.y += -1.0
	if Input.is_action_pressed("ui_down") or (mouse_pos.y / screen_size.y) > 0.96:
		move_direction.y += 1.0

#	NOTE: normalize direction vector so that camera moves at
#	the same speed in all directions
	move_direction = move_direction.normalized()

	if (move_direction != Vector2.ZERO):
		var zoom_ratio = sqrt(zoom.x)
		var shift_vector: Vector2 = move_direction * delta * cam_move_speed * zoom_ratio
		position = get_screen_center_position() + shift_vector
		
		camera_moved.emit(shift_vector)


func _unhandled_input(event):
	_zoom(event)


func _zoom(event):
	var new_zoom = zoom.x

	if event is InputEventMagnifyGesture:
		var zoom_amount = -(event.factor - 1.0) * zoom_sensitivity
		new_zoom = zoom.y + zoom_amount
	elif event is InputEventMouseButton:
#		Make zoom change slower as the camera gets more zoomed in
		var slow_down_multiplier = zoom.x / minimum_zoom_out
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

	if (new_zoom < maximum_zoom_in):
		new_zoom = maximum_zoom_in
	elif (new_zoom > minimum_zoom_out):
		new_zoom = minimum_zoom_out
	zoom = Vector2(new_zoom, new_zoom)
	
	camera_zoomed.emit(zoom)
