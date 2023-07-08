class_name AutocastButton 
extends Button


var _autocast: Autocast = null


func _ready():
	icon = load("res://Assets/icon.png")
	
	CooldownIndicator.add_to_button(_autocast, self)
	AutoModeIndicator.add_to_button(_autocast, self)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event):
	var pressed_shift_right_click: bool = event.is_action_released("right_click") && Input.is_action_pressed("shift")

	if pressed_shift_right_click:
		_autocast.toggle_auto_mode()


func set_autocast(autocast: Autocast):
	_autocast = autocast


func _on_mouse_entered():
	EventBus.autocast_button_mouse_entered.emit(_autocast)


func _on_mouse_exited():
	EventBus.autocast_button_mouse_exited.emit()
