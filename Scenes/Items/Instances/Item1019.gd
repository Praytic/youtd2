# Seeker's Arcane Oil
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.05, 0.002)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.05, 0.002)

