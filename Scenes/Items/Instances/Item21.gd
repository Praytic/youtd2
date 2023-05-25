# Orc War Spear
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.15, 0.0)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.2, 0.0)
