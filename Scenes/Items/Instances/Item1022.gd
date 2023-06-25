# Tears of the Gods
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.15, 0)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.05, 0)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.35, 0)
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.15, 0)
	modifier.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0)
