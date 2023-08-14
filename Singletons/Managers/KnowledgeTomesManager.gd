extends Node

signal knowledge_tomes_change()


const MAX_KNOWLEDGE_TOMES: int = 999999
const INITIAL_KNOWLEDGE_TOMES_INCOME: int = 8


var knowledge_tomes: int : set = set_knowledge_tomes
var income: int = INITIAL_KNOWLEDGE_TOMES_INCOME


func _ready():
	var starting_tomes: int = Config.starting_tomes()
	set_knowledge_tomes(starting_tomes)

	
func set_knowledge_tomes(value):
	knowledge_tomes = clampi(value, 0, MAX_KNOWLEDGE_TOMES)
	knowledge_tomes_change.emit()
	
func add_knowledge_tomes(value = income):
	set_knowledge_tomes(knowledge_tomes + value)


func spend(amount: int):
	knowledge_tomes -= amount
	knowledge_tomes_change.emit()


func get_current() -> int:
	return knowledge_tomes
