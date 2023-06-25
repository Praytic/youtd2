# Divine Oil of Sorcery
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.2, 0)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.05, 0)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0.4, 0)
