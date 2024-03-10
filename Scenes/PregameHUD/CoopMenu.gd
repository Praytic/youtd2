extends PregameTab


signal finished()


@export var _room_id_field: TextEdit
@export var _join_room_button: Button


func _on_join_room_button_pressed():
	var room_id: int = _room_id_field.text as int
	Network.set_room_id(room_id)
	finished.emit()


func _on_create_room_button_pressed():
	Network.generate_room_id()
	finished.emit()


func meets_condition() -> bool:
	return PregameSettings._player_mode == PlayerMode.enm.COOP


func _on_type_room_id_text_edit_text_changed():
	_join_room_button.disabled = _room_id_field.text.length() == 0
