# Ninja Glaive
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, 0.35, 0.0)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.025, 0.0)
