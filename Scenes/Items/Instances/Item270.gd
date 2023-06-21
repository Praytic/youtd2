# El Bastardo
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, 0.10, 0.01)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.05, 0.01)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.15, 0.02)
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.15, 0.01)
