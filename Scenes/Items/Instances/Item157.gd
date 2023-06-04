# Enchanted Bird Figurine
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.12, 0.0)
	modifier.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.28, 0.0)
