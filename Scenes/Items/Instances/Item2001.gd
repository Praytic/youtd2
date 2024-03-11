# Book of Force
extends Item


func on_consume():
	print_verbose("Book of Force was used. Adding 3 tomes.")
	
	get_player().add_tomes(3)
