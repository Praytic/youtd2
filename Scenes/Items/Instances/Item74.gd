# Axe of Decapitation
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, -0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, -0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, -0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, -0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 1.0, 0.0)
