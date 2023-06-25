# Tears of the Gods
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.12, 0)
	modifier.add_modification(Modification.Type.MOD_BUFF_DURATION, 0.12, 0)
	modifier.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.12, 0)
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.12, 0)
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, 0.12, 0)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.12, 0)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.12, 0)
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.12, 0)
