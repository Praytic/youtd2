# Elegant Ring
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.04, 0.0)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.04, 0.0)
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.10, 0.0)
