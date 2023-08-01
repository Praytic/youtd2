# Claws of Wisdom
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.16, 0.0)
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.80, 0.0)
