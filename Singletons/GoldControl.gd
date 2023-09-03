extends Node

# Singleton that manages gold and income


signal changed()


const MAX_GOLD = 999999

var _income_rate: float = 1.0
var _interest_rate: float = 0.05

var _gold: float
var _gold_farmed: float = 0.0


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
	var source_is_income: bool = true
	GoldControl.add_gold(income, source_is_income)

	Messages.add_normal("Income: %d upkeep, %d interest." % [upkeep, interest])


#########################
### Setters / Getters ###
#########################

func add_gold(value: float, source_is_income: bool = false):
#	NOTE: gold framed should include only gold gained from
#	creep kills or item/tower effects
	if !source_is_income:
		_gold_farmed += value

	var new_total: float = _gold + value
	_set_gold(new_total)


func spend_gold(value: float):
	var new_total: float = _gold - value
	_set_gold(new_total)


func _set_gold(value: float):
	if (value >= MAX_GOLD):
		print_debug("Max gold reached: %s" % value)
	elif (_gold < 0):
		print_debug("Negative gold reached: %s" % value)

	_gold = clampf(value, 0, MAX_GOLD)
	changed.emit()

func get_gold() -> float:
	return _gold


# Returns the sum of all gold gains
func get_gold_farmed() -> float:
	return _gold_farmed


func enough_gold_for_tower(tower_id: int) -> bool:
	var cost: float = TowerProperties.get_cost(tower_id)
	var current_gold: float = GoldControl.get_gold()
	var enough_gold: bool = cost <= current_gold

	return enough_gold
