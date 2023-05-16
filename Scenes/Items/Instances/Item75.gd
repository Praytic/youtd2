# Void Vial
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.50, 0.0)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, -0.10, 0.0)
