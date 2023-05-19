# Ring of Luck
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.077, 0.0)
