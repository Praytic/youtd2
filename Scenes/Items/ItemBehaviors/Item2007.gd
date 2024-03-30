# Divine Book of Omnipotence
extends ItemBehavior


func on_consume():
	item.get_player().add_tomes(15)
