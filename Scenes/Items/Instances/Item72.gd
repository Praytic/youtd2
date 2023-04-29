# Primitive Flute
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.06, 0.0)
