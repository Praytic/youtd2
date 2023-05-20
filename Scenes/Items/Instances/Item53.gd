# Mur'gul Slave
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.01, 0.001)
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.03, 0.002)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.005, 0.0005)
