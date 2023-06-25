# Arcane Oil of Sorcery
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.08, 0)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.02, 0)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0.16, 0)
