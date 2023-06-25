# Arcane Oil of Exuberance
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.4, 0)
