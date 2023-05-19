# Voodoo Doll
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.005)
