# Short Sword
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.05, 0.0)
