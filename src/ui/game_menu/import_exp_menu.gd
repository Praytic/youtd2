class_name ImportExpMenu extends Control


signal import_pressed()


@export var _exp_password_edit: TextEdit


#########################
###       Public      ###
#########################

func get_exp_password() -> String:
	var exp_password: String = _exp_password_edit.text
	
	return exp_password


#########################
###     Callbacks     ###
#########################

func _on_visibility_changed():
	_exp_password_edit.clear()


func _on_import_button_pressed():
	import_pressed.emit()


func _on_close_button_pressed():
	hide()
