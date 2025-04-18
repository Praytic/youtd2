extends ItemBehavior


func on_drop():
    var tower: Tower = item.get_carrier()

    tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, -tower.get_gold_cost() * 0.0001)


func on_pickup():
    var tower: Tower = item.get_carrier()

    tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, tower.get_gold_cost() * 0.0001)
