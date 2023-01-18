extends Camera2D

signal camera_moved(direction)
signal camera_zoomed()

export(float) var cam_move_speed = 500.0
export(float) var maximum_zoom_in = 0.15
export(float) var minimum_zoom_out = 10.0
export(float) var zoom_sensitivity = 1.0
export(float) var mousewheel_zoom_speed = 0.4
var move_direction: Vector2


func _ready():
	pass


func _physics_process(delta):
	if (move_direction != Vector2.ZERO):
		var diagonal_modif = 1
		if move_direction.abs() == Vector2.ONE:
			diagonal_modif *= sqrt(2.0)/2.0
		var shift_vector: Vector2 = move_direction * delta * cam_move_speed * diagonal_modif
		position = get_camera_position() + shift_vector
		
		emit_signal("camera_moved", shift_vector)


func _unhandled_input(event):
	_move(event)
	_zoom(event)


func _move(_event):
	var new_move_direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		new_move_direction.x = 1.0
	if Input.is_action_pressed("ui_up"):
		new_move_direction.y = -1.0
	if Input.is_action_pressed("ui_down"):
		new_move_direction.y = 1.0
	if Input.is_action_pressed("ui_left"):
		new_move_direction.x = -1.0
	
	self.move_direction = new_move_direction


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
			BUTTON_WHEEL_DOWN:
				new_zoom += zoom_change
			BUTTON_WHEEL_UP:
				new_zoom += -zoom_change
			_:
				return
	else:
		return

	if (new_zoom < maximum_zoom_in):
		new_zoom = maximum_zoom_in
	elif (new_zoom > minimum_zoom_out):
		new_zoom = minimum_zoom_out
	zoom = Vector2(new_zoom, new_zoom)
	
	emit_signal("camera_zoomed")
