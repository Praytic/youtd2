extends PregameTab


signal finished()


@export var _host_address_field: TextEdit
@export var _connect_button: Button


func _on_join_room_button_pressed():
	var address_details: Array = _host_address_field.text.split(":")
	Network.connect_to_server(address_details[0], address_details[1] as int)
	finished.emit()


func _on_create_room_button_pressed():
	Network.create_server()
	finished.emit()


func meets_condition() -> bool:
	return Globals._player_mode == PlayerMode.enm.COOP


func _on_type_room_id_text_edit_text_changed():
	_connect_button.disabled = _host_address_field.text.split(":", false).size() != 2
