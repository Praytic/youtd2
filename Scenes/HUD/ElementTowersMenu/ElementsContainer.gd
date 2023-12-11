# ElementsContainer
extends VBoxContainer


signal element_changed()


@onready var _button_group: ButtonGroup = load("res://Resources/UI/ButtonGroup/element_filter_button_group.tres")


var _current_element: Element.enm = Element.enm.ICE : set = set_element, get = get_element


func set_element(element: Element.enm):
	_current_element = element
	for button in _button_group.get_buttons():
		if button.element == element:
			button.set_pressed(true)
			break


func get_element() -> Element.enm:
	return _current_element


func _on_element_button_pressed():
	var pressed_button = _button_group.get_pressed_button()
	_current_element = pressed_button.element
	element_changed.emit()
