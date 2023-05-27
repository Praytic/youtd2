# Battle Suit
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.006)
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.01)
