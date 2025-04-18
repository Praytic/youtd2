extends TabContainer


signal close_pressed()


func _on_towers_close_pressed() -> void:
	close_pressed.emit()


func _on_encyclopedia_tab_items_close_pressed() -> void:
	close_pressed.emit()
