# Mine Cart
extends Item


func on_consume():
	get_player().modify_income_rate(0.10)
