# Consumable Hobbit
extends Item


func on_consume():
	get_player().modify_food_cap(8)
	get_player().add_tomes(20)
	get_player().modify_income_rate(0.06)
	get_player().get_team().modify_lives(2)
