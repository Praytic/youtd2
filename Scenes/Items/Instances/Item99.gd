# Rusty Mining Pick
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.12, 0.0)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -0.12, 0.0)
