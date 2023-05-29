# Mask of Sanity
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NORMAL, 0.20, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_CHAMPION, 0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, -0.25, 0.0)
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.10, 0.0025)
