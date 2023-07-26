# Amulet of Strength
extends Item


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_DPS_ADD, 400, 25)
    modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.112, 0.0)
