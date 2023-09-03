extends Node

signal changed()


const MAX_KNOWLEDGE_TOMES: int = 999999
const INITIAL_KNOWLEDGE_TOMES_INCOME: int = 8


var _knowledge_tomes: int
var _income: int = INITIAL_KNOWLEDGE_TOMES_INCOME


func _ready():
	var starting_tomes: int = Config.starting_tomes()
	_set_knowledge_tomes(starting_tomes)

	
func _set_knowledge_tomes(value):
	_knowledge_tomes = clampi(value, 0, MAX_KNOWLEDGE_TOMES)
	changed.emit()
	
func add_knowledge_tomes(value = _income):
	_set_knowledge_tomes(_knowledge_tomes + value)


func spend(amount: int):
	var new_value: int = _knowledge_tomes - amount
	_set_knowledge_tomes(new_value)


func get_current() -> int:
	return _knowledge_tomes


func enough_tomes_for_tower(tower_id: int) -> bool:
	var tome_cost: int = TowerProperties.get_tome_cost(tower_id)
	var enough_tomes: bool = tome_cost <= _knowledge_tomes

	return enough_tomes
