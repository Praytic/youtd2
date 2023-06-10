# Enchanted Gear
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.20, 0.0)
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.10, 0.0)
