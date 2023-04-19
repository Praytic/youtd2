extends Node

signal changed()


var _element_level_map: Dictionary = {}


func _init():
	for element in Tower.Element.values():
		_element_level_map[element] = 1


# TODO: call this when button that levels up elements is
# pressed
func increment(element: Tower.Element):
	_element_level_map[element] += 1
	changed.emit()


# TODO: move to class that stores this
func get_current(element: Tower.Element) -> int:
	var level: int = _element_level_map[element]

	return level
