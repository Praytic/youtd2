# Mini Tank
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DPS_ADD, 1000.0, 0.0)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.20, 0.002)
