# Consumable Chicken
extends Item


func on_consume():
	print_verbose("Consumable Chicken was used. Adding 2 food (not implemented.")

	FoodManager.modify_food_cap(2)
