# Inscribed Bark
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.15, 0.0)
