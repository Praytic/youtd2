class_name ExportExpMenu extends PopupPanel


@export var _exp_password_edit: TextEdit


#########################
###       Public      ###
#########################

func set_exp_password(value: String):
	_exp_password_edit.text = value


#########################
###     Callbacks     ###
#########################

func _on_close_button_pressed():
	hide()
