class_name AuthMenu extends PanelContainer


signal finished()
signal cancel_pressed()


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
		return
	W4Manager.last_request_status_updated.connect(_on_last_request_status_updated)
	W4Manager.auth_state_changed.connect(_on_auth_state_changed)
	await W4Manager.login()


#########################
###       Public      ###
#########################

func get_player_name() -> String:
	return _player_name_text_edit.text


#########################
###     Callbacks     ###
#########################

func _on_auth_state_changed():
	var current_state = W4Manager.current_state
	if current_state == W4Manager.State.AUTHENTICATED:
		finished.emit()


func _on_last_request_status_updated(message: String, is_error: bool):
	if is_error:
		_info_message_label.text = message
		_info_message_label.add_theme_color_override("font_color", Color.RED)
	else:
		_info_message_label.text = message
		_info_message_label.add_theme_color_override("font_color", Color.WHITE_SMOKE)


func _on_log_in_button_pressed():
	await W4Manager.set_own_username(_player_name_text_edit.text, false)


func _on_create_account_button_pressed():
	await W4Manager.set_own_username(_player_name_text_edit.text, true)


func _on_cancel_button_pressed():
	cancel_pressed.emit()
