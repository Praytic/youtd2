extends PanelContainer

signal close_pressed()


func _on_close_button_pressed():
	close_pressed.emit()
