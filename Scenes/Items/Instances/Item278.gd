# Amulet of Strength
extends Item


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_DPS, 400, 25)
    modifier.add_modification(Modification.Type.MOD_ATTACK_CRIT_CHANCE, 0.112, 0.0)
