extends VBoxContainer

# TODO: switch to Distribution enum

signal finished(distribution: int)


func _on_generic_button_pressed(distribution: int):
	finished.emit(distribution)


func _on_build_button_pressed():
	_on_generic_button_pressed(0)


func _on_random_button_pressed():
	_on_generic_button_pressed(1)


func _on_totally_random_button_pressed():
	_on_generic_button_pressed(2)
