extends Node

# Singleton that manages gold and income


signal gold_change(value)
signal income_change(value)


const MAX_GOLD = 999999
const INITIAL_INCOME = 10
const MAX_INCOME = 999999

var _income_rate: float = 1.0
var _interest_rate: float = 0.05

var _gold: float : set = set_gold, get = get_gold
var _income: float : set = set_income, get = get_income


#########################
### Code starts here  ###
#########################

func _ready():
	_gold = Config.starting_gold()
	_income = INITIAL_INCOME


func add_income():
	set_gold(_gold + _income)


func modify_income_rate(amount: float):
	_income_rate = _income_rate + amount


func modify_interest_rate(amount: float):
	_interest_rate = _interest_rate + amount


#########################
### Setters / Getters ###
#########################

func add_gold(value: float):
	var new_total: float = _gold + value
	set_gold(new_total)

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
	
func get_income_rate() -> float:
	return _income_rate

func get_interest_rate() -> float:
	return _interest_rate
