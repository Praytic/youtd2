# Bloodthirsty Axe
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.75, 0.0)
