# ItemFilterContainer
extends VBoxContainer


signal filter_changed()


func get_filter() -> Array:
	var buttons = get_children()
	var active_filter = []
	for button in buttons:
		if button.button_pressed:
			if typeof(button.filter_value) == TYPE_ARRAY:
				for filter_value in button.filter_value:
					active_filter.append(filter_value)
			else:
				active_filter.append(button.filter_value)
	return active_filter


func _on_filter_button_pressed(_value):
	filter_changed.emit()
