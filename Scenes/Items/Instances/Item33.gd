# Bomb Shells
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.50, 0.0)
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.05, 0.0)
