# Dull Gem
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.195, 0.0)
