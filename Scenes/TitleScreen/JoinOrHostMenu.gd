class_name JoinOrHostMenu extends VBoxContainer


signal join_pressed()
signal host_pressed()
signal cancel_pressed()


@export var _status_label: Label
@export var _address_text_edit: TextEdit
@export var _address_error_label: Label


#########################
###       Public      ###
#########################

func get_room_address() -> String:
	return _address_text_edit.text


func show_status_text(text: String):
	_status_label.text = text


func show_address_error():
	_address_error_label.show()


#########################
###     Callbacks     ###
#########################

func _on_join_button_pressed():
	join_pressed.emit()


func _on_host_button_pressed():
	host_pressed.emit()


func _on_cancel_button_pressed():
	cancel_pressed.emit()
