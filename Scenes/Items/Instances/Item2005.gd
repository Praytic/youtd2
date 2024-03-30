# Consumable Piggy
extends ItemBehavior


func on_consume():
	item.get_player().modify_food_cap(5)
