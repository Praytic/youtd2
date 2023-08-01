extends Node

# Singleton that manages gold and income


signal gold_change(value)


const MAX_GOLD = 999999

var _income_rate: float = 1.0
var _interest_rate: float = 0.05

var _gold: float : set = set_gold, get = get_gold


#########################
### Code starts here  ###
#########################

func _ready():
	_gold = Config.starting_gold()


func modify_income_rate(amount: float):
	_income_rate = _income_rate + amount


func modify_interest_rate(amount: float):
	_interest_rate = _interest_rate + amount


func add_income(wave_level: int):
	var upkeep: int = floori((20 + wave_level * 2) * _income_rate)
	var current_gold: int = floori(_gold)
	var interest: int = floori(min(current_gold * _interest_rate, 1000))
	var income: int = upkeep + interest
	GoldControl.add_gold(income)

	Messages.add_normal("Income: %d upkeep, %d interest." % [upkeep, interest])


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
