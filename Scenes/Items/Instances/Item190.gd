# Demonic Orb
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0.9, 0.0)
