# Divine Shield
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.45, 0.0)
