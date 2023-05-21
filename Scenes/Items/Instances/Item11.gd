# Land Mine
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, -0.25, 0.0)
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.20, 0.0)
