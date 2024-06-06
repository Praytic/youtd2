extends ItemBehavior


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_DPS_ADD, 400, 25)
    modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.112, 0.0)
