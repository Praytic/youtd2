extends Node

signal gold_change(value)

var gold: float : set = set_gold
var income: float = Properties.globals["ini_income"]
var max_gold: float = Properties.globals["max_gold"]

func _ready():
	set_gold(Properties.globals["ini_gold"])
	
func set_gold(value):
	if (value >= max_gold):
		gold = max_gold
	elif (gold < 0):
		gold = 0
	else:
		gold = value
	gold_change.emit(gold)

func add_gold(value = income):
	set_gold(gold + value)
