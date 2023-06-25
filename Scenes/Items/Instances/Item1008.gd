# Arcane Oil of Accuracy
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.016, 0)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.1, 0)
