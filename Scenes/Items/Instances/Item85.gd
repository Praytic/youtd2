# Blessed Holy Scepter
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DPS_ADD, 5.0, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.20, 0.0)
