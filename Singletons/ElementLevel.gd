extends Node

signal changed()

const MAX_ELEMENT_LEVEL = 15
const STARTING_ELEMENT_COST = 20

var _element_level_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	for element in Element.get_list():
		_element_level_map[element] = 0


#########################
###       Public      ###
#########################

func reset():
	var starting_level: int = Config.starting_research_level()

	for element in Element.get_list():
		_element_level_map[element] = starting_level
	
	changed.emit()


func increment(element: Element.enm):
	assert(element + 1 <= MAX_ELEMENT_LEVEL and element + 1 > 0, "Invalid element level.")
	_element_level_map[element] += 1
	changed.emit()


func get_current(element: Element.enm) -> int:
	var level: int = _element_level_map[element]

	return level


func get_max() -> int:
	return MAX_ELEMENT_LEVEL


func get_research_cost(element: Element.enm) -> int:
	var level: int = get_current(element)
	var cost: int = STARTING_ELEMENT_COST + level

	return cost


func can_afford_research(element: Element.enm) -> bool:
	var cost: int = ElementLevel.get_research_cost(element)
	var tome_count: int = KnowledgeTomesManager.get_current()
	var can_afford: bool = tome_count >= cost

	return can_afford

func is_able_to_research(element: Element.enm) -> bool:
	var can_afford: bool = can_afford_research(element)
	var current_level: int = get_current(element)
	var reached_max_level: bool = current_level == ElementLevel.get_max()
	var is_able: bool = can_afford && !reached_max_level

	return is_able
