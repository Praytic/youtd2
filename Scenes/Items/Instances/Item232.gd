# Ring of Chance
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.18, 0.0)
