# Crystal Staff
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.25, 0.01)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.20, 0.006)
