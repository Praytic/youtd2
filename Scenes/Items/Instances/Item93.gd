# Gift of the Wild
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.125, 0.0)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.125, 0.0)
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.125, 0.0)
	modifier.add_modification(Modification.Type.MOD_MANA_PERC, 0.125, 0.0)
