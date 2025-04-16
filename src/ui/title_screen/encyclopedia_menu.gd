extends TabContainer


signal close_pressed()


func _on_towers_close_pressed() -> void:
	close_pressed.emit()
