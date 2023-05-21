# Dumpster
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.30, 0.01)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -0.40, 0.0)
