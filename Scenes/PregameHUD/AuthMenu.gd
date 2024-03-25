class_name AuthMenu extends PregameTab


@export var _player_name_text_edit: TextEdit
@export var _info_message_label: Label

#########################
###     Built-in      ###
#########################

# NOTE: To disable login and authentication set Config variable
# config/enable_auth=false. If it's not disabled, players will
# be automatically logged in using their local device ID.
func _ready():
	if !Config.enable_auth():
#		This is the simpliest way to disable W4GD addon in realtime right now.
#		Follow https://gitlab.com/W4Games/sdk/w4gd/-/issues/1 for more info.
		get_tree().get_root().get_node("W4GD").queue_free()
		return
	await W4Manager.login()


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
	_on_generic_button_pressed()


func _on_create_account_button_pressed():
	await W4Manager.set_own_username(_player_name_text_edit.text)
	_on_generic_button_pressed()
