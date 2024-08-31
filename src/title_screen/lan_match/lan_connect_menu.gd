class_name LanConnectMenu extends PanelContainer


signal join_pressed()
signal cancel_pressed()
signal create_room_pressed()


@export var _address_edit: LineEdit


#########################
###       Public      ###
#########################

func get_entered_address() -> String:
	return _address_edit.text


#########################
###     Callbacks     ###
#########################

func _on_cancel_button_pressed():
	cancel_pressed.emit()


func _on_create_button_pressed():
	create_room_pressed.emit()


func _on_join_button_pressed():
	join_pressed.emit()
