extends Camera2D

export(float) var cam_move_speed = 500.0
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
	self.move_direction = new_move_direction
