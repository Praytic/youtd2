# Ogre Battle Axe
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.25, 0.01)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.05, 0.0)
