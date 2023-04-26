# Undead Claws
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.15, 0.0)
