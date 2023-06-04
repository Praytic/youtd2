# Flaming Arrow
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.10, 0.005)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.1, 0.0)
