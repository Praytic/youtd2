extends ItemBehavior


func on_consume():
	item.get_player().add_tomes(8)
