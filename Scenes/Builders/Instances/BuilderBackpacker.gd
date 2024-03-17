extends Builder


func _init():
    _item_slots_bonus = 2
    _adds_extra_recipes = true


func _get_tower_modifier() -> Modifier:
    var mod: Modifier = Modifier.new()
    mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.40, 0.0)

    return mod


func _get_tower_buff() -> BuffType:
    var backpacker_bt: BuffType = BuffType.new("", 0, 0, false, self)
    backpacker_bt.add_periodic_event(backpacker_bt_periodic, 1.0)

    return backpacker_bt


func backpacker_bt_periodic(event: Event):
    var buff: Buff = event.get_buff()
    var tower: Tower = buff.get_buffed_unit()
    var item_list: Array[Item] = tower.get_items()

    var tower_rarity: Rarity.enm = TowerProperties.get_rarity(tower.get_id())

    var dropped_items: bool = false

    for item in item_list:
        var item_rarity: Rarity.enm = item.get_rarity()
        var can_wield_item: bool = item_rarity == tower_rarity || item_rarity == Rarity.enm.UNIQUE
        
        if !can_wield_item:
            item.drop()
            item.fly_to_stash(0.0)
            dropped_items = true
    
    if dropped_items:
        tower.get_player().display_floating_text("Backpacker: Item must have same rarity as tower!", tower, Color.RED)
