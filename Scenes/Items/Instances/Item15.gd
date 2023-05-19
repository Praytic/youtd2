# Outworn Spell Book
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.03, 0.0)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0.1, 0.0)
