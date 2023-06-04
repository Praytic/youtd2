# Lightning Boots
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.30, 0.004)
	modifier.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, -1.0, 0.0)
