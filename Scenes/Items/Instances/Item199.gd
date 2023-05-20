# Dowsing Rod
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, -0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.25, 0.0)
