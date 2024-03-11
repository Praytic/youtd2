# Arcane Book of Power
extends Item


func on_consume():
	get_player().add_tomes(8)
