# Wizard's Soul
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.3, 0)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.06, 0)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0.5, 0)
	modifier.add_modification(Modification.Type.MOD_MANA_PERC, 0.5, 0)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.5, 0)
