extends Node

signal knowledge_tomes_change(value)

var knowledge_tomes: int : set = set_knowledge_tomes
var income: int = Properties.globals["ini_knowledge_tomes_income"]
var max_kt: int = Properties.globals["max_knowledge_tomes"]

func _ready():
	set_knowledge_tomes(Properties.globals["ini_knowledge_tomes"])
	
func set_knowledge_tomes(value):
	if (value >= max_kt):
		knowledge_tomes = max_kt
	elif (value < 0):
		knowledge_tomes = 0
	else:
		knowledge_tomes = value
	emit_signal("knowledge_tomes_change", value)
	
func add_knowledge_tomes(value = income):
	set_knowledge_tomes(knowledge_tomes + value)
