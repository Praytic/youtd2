extends Node

# Emitted when current food or food cap changes
signal changed()


const MAX_FOOD_CAP: int = 99
const INITIAL_FOOD_CAP: int = 55

var current_food: int = 0
var food_cap: int = INITIAL_FOOD_CAP


func enough_food_for_tower(tower_id: int) -> bool:
	if Config.unlimited_food():
		return true
	
	var food_cost: int = TowerProperties.get_food_cost(tower_id)
	var food_after_add: int = current_food + food_cost
	var enough_food: bool = food_after_add <= food_cap

	return enough_food


func add_tower(tower_id: int):
	var food_cost: int = TowerProperties.get_food_cost(tower_id)
	var new_food: int = current_food + food_cost

	if new_food > food_cap and not Config.unlimited_food():
		push_error("Tried to change food above cap.")

		return

	current_food = new_food
	changed.emit()


func remove_tower(tower_id: int):
	var food_cost: int = TowerProperties.get_food_cost(tower_id)
	var new_food: int = current_food - food_cost
	
	if new_food < 0:
		push_error("Tried to change food below 0.")

		return
	
	current_food = new_food
	changed.emit()


func modify_food_cap(amount: int):
	food_cap = clampi(food_cap + amount, 0, MAX_FOOD_CAP)
	changed.emit()


func get_current_food() -> int:
	return current_food


func get_food_cap() -> int:
	return food_cap
