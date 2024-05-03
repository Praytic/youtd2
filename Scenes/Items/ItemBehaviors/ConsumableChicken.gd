extends ItemBehavior


func on_consume():
	item.get_player().modify_food_cap(2)
