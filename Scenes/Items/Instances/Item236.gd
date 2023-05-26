# Veteran's Tome of Battle
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.60, 0.0)
