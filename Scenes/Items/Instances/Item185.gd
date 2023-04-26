# Sniper
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, 0.15, 0.0)
