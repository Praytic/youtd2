# Troll Charm
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.05, 0.0)
	modifier.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.30, 0.0)
