class_name AuthMenu extends PregameTab


@export var _player_name_text_edit: TextEdit
@export var _info_message_label: Label

#########################
###       Public      ###
#########################

func get_player_name() -> String:
	return _player_name_text_edit.text


#########################
###     Callbacks     ###
#########################

func _on_generic_button_pressed():
	if W4Manager.has_error:
		_info_message_label.text = W4Manager.last_error
		_info_message_label.color = Color.ORANGE_RED
	finished.emit()


func _on_log_in_button_pressed():
	W4Manager.login()
	_on_generic_button_pressed()


func _on_create_account_button_pressed():
	W4Manager.login()
	W4Manager.set_own_username(_player_name_text_edit.text)
	_on_generic_button_pressed()
