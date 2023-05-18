extends Node

signal knowledge_tomes_change()


var knowledge_tomes: int : set = set_knowledge_tomes
var income: int = Properties.globals["ini_knowledge_tomes_income"]
var max_kt: int = Properties.globals["max_knowledge_tomes"]

func _ready():
	var starting_tomes: int = Config.starting_tomes()
	set_knowledge_tomes(starting_tomes)

	
func set_knowledge_tomes(value):
	if (value >= max_kt):
		knowledge_tomes = max_kt
	elif (value < 0):
		knowledge_tomes = 0
	else:
		knowledge_tomes = value
	knowledge_tomes_change.emit()
	
func add_knowledge_tomes(value = income):
	set_knowledge_tomes(knowledge_tomes + value)


func spend(amount: int):
	knowledge_tomes -= amount


func get_current() -> int:
	return knowledge_tomes
