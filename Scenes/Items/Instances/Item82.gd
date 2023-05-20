# Touch of a Spirit
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, -0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.50, 0.0)
