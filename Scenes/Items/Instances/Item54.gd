# Tiny Rabbit
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.02, 0.0)
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.02, 0.0)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.02, 0.0)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.02, 0.0)
	modifier.add_modification(Modification.Type.MOD_MANA_PERC, 0.02, 0.0)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.02, 0.0)
