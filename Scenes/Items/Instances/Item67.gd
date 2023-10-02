# Floating Mark
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.02, 0.001)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.02, 0.0)
