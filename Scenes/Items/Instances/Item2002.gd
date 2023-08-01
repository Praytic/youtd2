# Consumable Plant
extends Item


func on_consume():
	print_verbose("Consumable Plant was used. Adding 1 food (not implemented.")

	FoodManager.modify_food_cap(1)
