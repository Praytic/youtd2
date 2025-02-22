extends ItemBehavior


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.50, 0.0)


func on_drop():
    var tower: Tower = item.get_carrier()
    var target_count: int = tower.get_target_count_from_item()
    tower.set_target_count_from_item(target_count - 3)


func on_pickup():
    var tower: Tower = item.get_carrier()
    var target_count: int = tower.get_target_count_from_item()
    tower.set_target_count_from_item(target_count + 3)
