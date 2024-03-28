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
		var w4_node: Node = get_tree().get_root().get_node_or_null("W4GD")
		
		if w4_node != null:
			get_tree().get_root().get_node("W4GD").queue_free()
	
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
