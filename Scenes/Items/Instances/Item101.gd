# Thunder Gloves
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.20, 0.0)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_DAMAGE, 0.7, 0.0)
