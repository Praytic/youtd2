class_name CoopMenu extends PregameTab


@export var _host_address_field: TextEdit
@export var _address_error_label: Label


#########################
###       Public      ###
#########################

func get_room_address() -> String:
	return _host_address_field.text


func show_address_error():
	_address_error_label.show()


#########################
###     Callbacks     ###
#########################

func _on_join_room_button_pressed():
	EventBus.player_requested_to_join_room.emit()


func _on_create_room_button_pressed():
	EventBus.player_requested_to_host_room.emit()
