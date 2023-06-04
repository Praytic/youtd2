# Heavy Crossbow
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_DPS_ADD, 215, 0.0)
