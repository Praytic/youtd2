# Blunt Club
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.025, 0.0)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.01, 0.0)
