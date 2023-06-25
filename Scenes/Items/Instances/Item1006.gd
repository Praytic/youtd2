# Divine Oil of Magic
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_PERC, 0.4, 0)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.4, 0)
