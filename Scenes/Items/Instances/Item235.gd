# Hermit Staff
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.125, 0.0)
	modifier.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.33, 0.0)
