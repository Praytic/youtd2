extends VBoxContainer


signal finished(distribution: Distribution.enm)


func _on_generic_button_pressed(distribution: Distribution.enm):
	finished.emit(distribution)


func _on_build_button_pressed():
	_on_generic_button_pressed(Distribution.enm.BUILD)


func _on_random_button_pressed():
	_on_generic_button_pressed(Distribution.enm.RANDOM_WITH_UPGRADES)


func _on_totally_random_button_pressed():
	_on_generic_button_pressed(Distribution.enm.TOTALLY_RANDOM)
