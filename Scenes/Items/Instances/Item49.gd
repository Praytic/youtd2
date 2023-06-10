# Scepter of the Lunar Light
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.50, 0.0)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.12, 0.0)
