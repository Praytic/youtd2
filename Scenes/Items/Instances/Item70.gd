# Collection of Stories
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.14, 0.0)
