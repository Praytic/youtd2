extends Node

signal changed()


const MAX_KNOWLEDGE_TOMES: int = 999999
const INITIAL_KNOWLEDGE_TOMES_INCOME: int = 8


var knowledge_tomes: int : set = set_knowledge_tomes
var income: int = INITIAL_KNOWLEDGE_TOMES_INCOME


func _ready():
	var starting_tomes: int = Config.starting_tomes()
	set_knowledge_tomes(starting_tomes)

	
func set_knowledge_tomes(value):
	knowledge_tomes = clampi(value, 0, MAX_KNOWLEDGE_TOMES)
	changed.emit()
	
func add_knowledge_tomes(value = income):
	set_knowledge_tomes(knowledge_tomes + value)


func spend(amount: int):
	var new_value: int = knowledge_tomes - amount
	set_knowledge_tomes(new_value)


func get_current() -> int:
	return knowledge_tomes


func enough_tomes_for_tower(tower_id: int) -> bool:
	var tome_cost: int = TowerProperties.get_tome_cost(tower_id)
	var enough_tomes: bool = tome_cost <= knowledge_tomes

	return enough_tomes
