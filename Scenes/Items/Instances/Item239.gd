# Secret Tome of Mana
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_PERC, 2.0, 0.0)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, -1.0, 0.0)
