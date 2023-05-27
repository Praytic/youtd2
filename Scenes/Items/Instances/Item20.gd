# Combat Gloves
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.40, 0.008)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.40, 0.008)
