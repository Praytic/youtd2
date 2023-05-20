# Mark of the Claw
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD, 0.07, 0.0)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.04, 0.0)
