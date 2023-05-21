# Spider Silk
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.50, 0.01)
