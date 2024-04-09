extends VBoxContainer


signal close_pressed()


@export var _name_edit: TextEdit


#########################
###     Built-in      ###
#########################

func _ready():
	var player_name: String = Settings.get_setting(Settings.PLAYER_NAME)
	_name_edit.text = player_name


#########################
###     Callbacks     ###
#########################

func _on_name_edit_text_changed():
	var new_player_name: String = _name_edit.text
	Settings.set_setting(Settings.PLAYER_NAME, new_player_name)
	Settings.flush()


func _on_close_button_pressed():
	close_pressed.emit()
