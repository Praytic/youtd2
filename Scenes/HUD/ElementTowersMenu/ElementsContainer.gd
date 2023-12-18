# ElementsContainer
extends VBoxContainer


signal element_changed()


var _current_element: Element.enm = Element.enm.ICE : get = get_element


func get_element() -> Element.enm:
	return _current_element


func _on_element_button_pressed(element: Element.enm):
	_current_element = element
	for button in get_children():
		var is_current = button.element == _current_element
		var is_researched = ElementLevel.get_current(button.element) > 0 
		if is_current or is_researched:
			button.set_pressed_no_signal(true)
		else:
			button.set_pressed_no_signal(false)
	element_changed.emit()
