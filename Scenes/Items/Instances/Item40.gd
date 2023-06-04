# Gargoyle Wing
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 1.0, 0.01)
