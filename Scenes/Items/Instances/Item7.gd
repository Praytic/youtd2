# Heavy Gun
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.25, 0.0)
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.75, 0.0)
