# Crystalline Arrow
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, -0.15, 0.0)
	modifier.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)
