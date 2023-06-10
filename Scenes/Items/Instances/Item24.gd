# Moonsilver Circlet
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.20, 0.0)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 1.0, 0.0)
