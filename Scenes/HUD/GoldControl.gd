extends Control


signal gold_change(value)
signal income_change(value)


const INITIAL_GOLD = 70
const MAX_GOLD = 999999
const INITIAL_INCOME = 10
const MAX_INCOME = 999999


var _gold: float : set = set_gold, get = get_gold
var _income: float : set = set_income, get = get_income


#########################
### Code starts here  ###
#########################

func _ready():
	_gold = INITIAL_GOLD
	_income = INITIAL_INCOME


func add_income():
	set_gold(_gold + _income)


#########################
###     Callbacks     ###
#########################

func _on_Creep_death(_event: Event, creep: Creep):
	var bounty = creep.get_bounty()
	set_gold(_gold + bounty)


#########################
### Setters / Getters ###
#########################

func set_gold(value: float):
	if (value >= MAX_GOLD):
		print_debug("Max gold reached: %s" % value)
		_gold = MAX_GOLD
	elif (_gold < 0):
		print_debug("Negative gold reached: %s" % value)
		_gold = 0
	else:
		_gold = value
	gold_change.emit(_gold)

func get_gold() -> float:
	return _gold

func get_income() -> float:
	return _income

func set_income(value: float):
	if (value >= MAX_INCOME):
		print_debug("Max income reached: %s" % value)
		_income = MAX_INCOME
	elif (_gold < 0):
		print_debug("Negative income reached: %s" % value)
		_income = 0
	else:
		_income = value
	income_change.emit(_income)
	

