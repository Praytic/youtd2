class_name ElementsContainer extends VBoxContainer


signal element_changed()


#########################
###       Public      ###
#########################

func get_element() -> Element.enm:
	var buttons: Array[Node] = get_children()
	
	for button in buttons:
		if button.button_pressed:
			var element: Element.enm = button.element
			
			return element
	
	var fallback_element: Element.enm = Element.enm.ICE
	
	return fallback_element

#########################
###     Callbacks     ###
#########################

func _on_element_button_pressed(_button_pressed: bool):
	element_changed.emit()
