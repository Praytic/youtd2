# Lucky Dice
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.025, 0.002)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.025, 0.002)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.05, 0.004)
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.025, 0.002)
