# Magic Vial
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.10, 0.004)
	modifier.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.10, 0.004)
