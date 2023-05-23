# Crystalized Scales
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.24, 0.0)
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.18, 0.0)
