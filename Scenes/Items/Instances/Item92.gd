# Inscribed Pebble
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.24, 0.0)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.10, 0.0)
