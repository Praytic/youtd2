# Holy Axe
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.15, 0.0)
