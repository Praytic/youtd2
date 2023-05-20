# Mana Shell
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_PERC, 0.195, 0.0)
