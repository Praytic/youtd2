class_name MissionsMenu extends PanelContainer


signal close_pressed()


func _on_close_button_pressed() -> void:
	close_pressed.emit()
