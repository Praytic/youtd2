# Fairy's Wand
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.1, 0.0)

