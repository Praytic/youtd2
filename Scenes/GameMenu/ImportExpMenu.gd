class_name ImportExpMenu extends PopupPanel


signal import_pressed()


@export var _exp_password_edit: TextEdit
@export var _error_label: Label
@export var _success_label: RichTextLabel


#########################
###       Public      ###
#########################

func get_exp_password() -> String:
	var exp_password: String = _exp_password_edit.text
	
	return exp_password


func show_error_label():
	_success_label.hide()
	_error_label.show()


func show_success_label(player_exp: int):
	_error_label.hide()

	var text: String = "Successfully imported experience password. You now have [color=GOLD]%d[/color] experience!" % player_exp
	_success_label.clear()
	_success_label.append_text(text)
	_success_label.show()


#########################
###     Callbacks     ###
#########################

func _on_visibility_changed():
	_exp_password_edit.clear()
	_error_label.hide()
	_success_label.hide()


func _on_import_button_pressed():
	import_pressed.emit()


func _on_close_button_pressed():
	hide()
