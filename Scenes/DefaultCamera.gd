extends Camera2D

signal stop_moving_camera()

export(float) var cam_move_speed = 500.0
var move_direction: Vector2
	
func _ready():
	connect("stop_moving_camera", self, "_on_stop_moving_camera")

func _physics_process(delta):
	if (move_direction != Vector2.ZERO):
		var diagonal_modif = 1
		if move_direction.abs() == Vector2.ONE:
			diagonal_modif *= sqrt(2.0)/2.0
		position = get_camera_position() + move_direction * delta * cam_move_speed * diagonal_modif

func _unhandled_input(event):
	var move_direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		move_direction.x = 1.0
	if Input.is_action_pressed("ui_up"):
		move_direction.y = -1.0
	if Input.is_action_pressed("ui_down"):
		move_direction.y = 1.0
	if Input.is_action_pressed("ui_left"):
		move_direction.x = -1.0
	self.move_direction = move_direction

func _on_stop_moving_camera():
	move_direction = Vector2.ZERO
