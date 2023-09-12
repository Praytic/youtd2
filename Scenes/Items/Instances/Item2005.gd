# Consumable Piggy
extends Item


func on_consume():
	FoodManager.modify_food_cap(5)
