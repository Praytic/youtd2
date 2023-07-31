# Mine Cart
extends Item


func on_consume():
	GoldControl.modify_income_rate(0.10)
