extends ItemBehavior


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_DPS_ADD, 1230, 0.0)
