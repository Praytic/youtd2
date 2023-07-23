extends Button


# Need this script to reroute shift right click event into a
# signal. Can't place _gui_input() in ItemButton.gd
# because root node of ItemButton is a Margin
# Container not the button itself.


signal right_clicked()


func _gui_input(event):
	var pressed_right_click: bool = event.is_action_released("right_click")

	if pressed_right_click:
		right_clicked.emit()
