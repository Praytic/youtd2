# Elite Sharp Shooter
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.35, 0.0)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.05, 0.0)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.5, 0.0)
	modifier.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 2.0, 0.0)
