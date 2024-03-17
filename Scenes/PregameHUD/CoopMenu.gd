extends PregameTab


@export var _host_address_field: TextEdit
@export var _address_error_label: Label


func _on_join_room_button_pressed():
#	TODO: check validity more thoroughly
	var address_is_valid: bool = _host_address_field.text.split(":", false).size() == 2
	
	if !address_is_valid:
		_address_error_label.show()
		
		return
	
	var address_details: Array = _host_address_field.text.split(":")
	Network.connect_to_server(address_details[0], address_details[1] as int)
	finished.emit()


func _on_create_room_button_pressed():
	Network.create_server()
	finished.emit()
