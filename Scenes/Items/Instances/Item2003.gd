# Consumable Chicken
extends Item


func on_consume():
	get_player().modify_food_cap(2)
