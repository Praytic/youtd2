class_name ElementsContainer extends VBoxContainer


signal element_changed()


var _current_element: Element.enm = Element.enm.ICE : get = get_element


#########################
###       Public      ###
#########################

func get_element() -> Element.enm:
	return _current_element


func update_element_level(element_levels: Dictionary):
	for button in get_children():
		var element: Element.enm = button.element
		var level: int = element_levels[element]
		button.set_element_level(level)


#########################
###     Callbacks     ###
#########################

func _on_element_button_pressed(element: Element.enm):
	_current_element = element
	element_changed.emit()
