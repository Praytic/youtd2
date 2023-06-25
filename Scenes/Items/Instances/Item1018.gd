# Seeker's Oil
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.02, 0.0008)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.02, 0.0008)
