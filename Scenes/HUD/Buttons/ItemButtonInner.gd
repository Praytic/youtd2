extends TextureButton


# Need this script to reroute shift right click event into a
# signal. Can't place _gui_input() in ItemButton.gd
# because root node of ItemButton is a Margin
# Container not the button itself.


signal shift_right_clicked()
signal right_clicked()


func _gui_input(event):
	var pressed_shift_right_click: bool = event.is_action_released("right_click") && Input.is_action_pressed("shift")
	var pressed_right_click: bool = event.is_action_released("right_click")

	if pressed_shift_right_click:
		shift_right_clicked.emit()
	elif pressed_right_click:
		right_clicked.emit()
