# Shadowfoot's Mantle
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.45, 0.0)
