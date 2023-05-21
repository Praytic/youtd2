# Survival Kit
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.05, 0.0)
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.05, 0.0)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.05, 0.0)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.05, 0.0)
