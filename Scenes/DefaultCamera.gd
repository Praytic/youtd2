extends Camera2D

export(float) var cam_move_speed = 500.0
export(float) var maximum_zoom_in = 0.15
export(float) var minimum_zoom_out = 10
export(float) var zoom_sensitivity = 1.0
var move_direction: Vector2
	
func _ready():
	pass

func _physics_process(delta):
	if (move_direction != Vector2.ZERO):
		var diagonal_modif = 1
		if move_direction.abs() == Vector2.ONE:
			diagonal_modif *= sqrt(2.0)/2.0
		position = get_camera_position() + move_direction * delta * cam_move_speed * diagonal_modif

func _unhandled_input(_event):
	var new_move_direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		new_move_direction.x = 1.0
	if Input.is_action_pressed("ui_up"):
		new_move_direction.y = -1.0
	if Input.is_action_pressed("ui_down"):
		new_move_direction.y = 1.0
	if Input.is_action_pressed("ui_left"):
		new_move_direction.x = -1.0
	
	_zoom(_event)
	self.move_direction = new_move_direction

func _zoom(event):
	var factor
	if event is InputEventMagnifyGesture:
		factor = event.factor
	elif event is InputEventMouseButton:
		match event.get_button_index():
			BUTTON_WHEEL_DOWN, BUTTON_WHEEL_UP:
				factor = event.factor
	if not factor: 
		return
	
	var zoom_amount = -(factor - 1.0) * zoom_sensitivity
	var new_zoom = zoom.y + zoom_amount
	if (new_zoom < maximum_zoom_in):
		new_zoom = maximum_zoom_in
	elif (new_zoom > minimum_zoom_out):
		new_zoom = minimum_zoom_out
	zoom = Vector2(new_zoom, new_zoom)
