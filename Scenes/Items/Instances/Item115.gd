# Obsidian Figurine
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.175, 0.0)
