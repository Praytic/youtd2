# Secret Tome of Magic
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, -0.15, -0.01)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 2.0, 0.2)
