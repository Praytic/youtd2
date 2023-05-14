extends Node

signal changed()

const STARTING_RESEARCH_LEVEL: String = "application/config/starting_research_level"

var _element_level_map: Dictionary = {}


func _init():
	var starting_level: int = 0

	if ProjectSettings.has_setting(STARTING_RESEARCH_LEVEL):
		starting_level = ProjectSettings.get_setting(STARTING_RESEARCH_LEVEL) as int

	for element in Tower.Element.values():
		_element_level_map[element] = starting_level


# TODO: call this when button that levels up elements is
# pressed
func increment(element: Tower.Element):
	_element_level_map[element] += 1
	changed.emit()


# TODO: move to class that stores this
func get_current(element: Tower.Element) -> int:
	var level: int = _element_level_map[element]

	return level


func get_research_cost(element: Tower.Element) -> int:
	var level: int = get_current(element)
	var cost: int = 20 + level

	return cost


func can_afford_research(element: Tower.Element) -> bool:
	var cost: int = ElementLevel.get_research_cost(element)
	var tome_count: int = KnowledgeTomesManager.get_current()
	var can_afford: bool = tome_count >= cost

	return can_afford
