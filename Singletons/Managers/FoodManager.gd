extends Node

signal changed()


const MAX_FOOD_CAP: int = 99
const INITIAL_FOOD_CAP: int = 55
const FOOD_PER_TOWER: int = 2

var current_food: int = 0
var food_cap: int = INITIAL_FOOD_CAP


func enough_food_for_tower() -> bool:
	var food_after_add: int = current_food + FOOD_PER_TOWER
	var enough_food: bool = food_after_add <= food_cap

	return enough_food


func add_tower():
	var new_food: int = current_food + FOOD_PER_TOWER

	if new_food > food_cap:
		push_error("Tried to change food above cap.")

		return

	current_food = new_food
	changed.emit()


func remove_tower():
	var new_food: int = current_food - FOOD_PER_TOWER
	
	if new_food < 0:
		push_error("Tried to change food below 0.")

		return
	
	current_food = new_food
	changed.emit()


func get_current_food() -> int:
	return current_food


func get_food_cap() -> int:
	return food_cap
