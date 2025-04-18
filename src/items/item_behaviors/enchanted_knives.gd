extends ItemBehavior


func on_drop():
    var tower: Tower = item.get_carrier()
    var target_count: int = tower.get_target_count_from_item()
    tower.set_target_count_from_item(target_count - 3)


func on_pickup():
    var tower: Tower = item.get_carrier()
    var target_count: int = tower.get_target_count_from_item()
    tower.set_target_count_from_item(target_count + 3)
