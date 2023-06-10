# Dragon Claws
extends Item


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.10, 0.005)
    modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.05, 0.001)
