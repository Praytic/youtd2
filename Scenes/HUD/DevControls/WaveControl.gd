extends Control


func _on_DevControlButton_toggled(button_pressed: bool):
	if button_pressed:
		show()
	else:
		hide()
