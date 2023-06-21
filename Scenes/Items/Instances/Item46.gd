# Minds Key
extends Item


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.025, 0.001)
    modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.15, 0.006)
