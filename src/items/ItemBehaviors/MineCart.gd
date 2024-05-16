extends ItemBehavior


func on_consume():
	item.get_player().modify_income_rate(0.10)
