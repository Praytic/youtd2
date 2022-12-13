extends Camera2D

signal stop_moving_camera()

export(float) var cam_move_speed = 200.0
var move_direction: Vector2
	
func _ready():
	connect("stop_moving_camera", self, "_on_stop_moving_camera")

func _physics_process(delta):
	if (move_direction != Vector2.ZERO):
		if move_direction.abs() == Vector2.ONE:
			position += move_direction * delta * cam_move_speed
		position += move_direction * delta * cam_move_speed
		print(move_direction * delta * cam_move_speed)

func _unhandled_input(event):
	if event.is_action_pressed("ui_right"):
		move_direction.x += 1.0
	if event.is_action_pressed("ui_up"):
		move_direction.y -= 1.0
	if event.is_action_pressed("ui_down"):
		move_direction.y += 1.0
	if event.is_action_pressed("ui_left"):
		move_direction.x -= 1.0
		
	if event.is_action_released("ui_right") or event.is_action_released("ui_left"):
		move_direction.x = 0
	if event.is_action_released("ui_up") or event.is_action_released("ui_down"):
		move_direction.y = 0
		
	if move_direction.abs() == Vector2.ONE:
		move_direction *= sqrt(2.0)/2.0
		
func _on_stop_moving_camera():
	move_direction = Vector2.ZERO
