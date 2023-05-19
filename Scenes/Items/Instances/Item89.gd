# Bull Axe
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.325, 0.0)
