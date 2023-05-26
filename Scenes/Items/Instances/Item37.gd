# Mini Sheep
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.25, 0.0)
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.125, 0.0)
