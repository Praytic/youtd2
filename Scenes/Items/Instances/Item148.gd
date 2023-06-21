# Naga Trident
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.07, 0.0)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.08, 0.0)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.8, 0.0)
