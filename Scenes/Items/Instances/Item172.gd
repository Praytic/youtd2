# Sacred Halo
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.84, 0.0)
	modifier.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.20, 0.0)
