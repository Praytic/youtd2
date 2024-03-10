extends PregameTab


signal finished()


func _on_join_room_button_pressed():
	finished.emit()


func _on_create_room_button_pressed():
	finished.emit()


func meets_condition() -> bool:
	return PregameSettings._player_mode == PlayerMode.enm.COOP
