class_name JoinOrHostMenu extends VBoxContainer


signal join_button_pressed()
signal host_button_pressed()
signal cancel_pressed()


func _on_join_button_pressed():
	join_button_pressed.emit()


func _on_host_button_pressed():
	host_button_pressed.emit()


func _on_cancel_button_pressed():
	cancel_pressed.emit()
