extends Node


signal gold_change(value)


const INITIAL_GOLD = 70
const MAX_GOLD = 999999
const INITIAL_INCOME = 10
const MAX_INCOME = 999999


var _gold: float : set = set_gold, get = get_gold
var income: float = Properties.globals["ini_income"]
var max_gold: float = Properties.globals["max_gold"]


func _ready():
	set_gold(Properties.globals["ini_gold"])


func set_gold(value):
	if (value >= max_gold):
		print_debug("Max gold reached: %s" % value)
		_gold = max_gold
	elif (_gold < 0):
		print_debug("Negative gold reached: %s" % value)
		_gold = 0
	else:
		_gold = value
	gold_change.emit(_gold)


func get_gold(value)


func add_gold(value = income):
	set_gold(_gold + value)

