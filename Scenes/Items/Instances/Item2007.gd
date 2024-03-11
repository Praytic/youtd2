# Divine Book of Omnipotence
extends Item


func on_consume():
	get_player().add_tomes(15)
