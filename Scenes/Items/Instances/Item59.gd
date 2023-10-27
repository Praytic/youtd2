# Silver Armor
extends Item


func get_ability_description() -> String:
    var text: String = ""

    text += "[color=GOLD]Blindingly Polished Armor[/color]\n"
    text += "This item shines so searingly that it grants [carrier's goldcost / 100]% bonus attack damage.\n"

    return text


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.05, 0.0)
    modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.10, 0.0)


func on_drop():
    var itm: Item = self
    var tower: Tower = itm.get_carrier()

    tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, -tower.get_gold_cost() * 0.0001)


func on_pickup():
    var itm: Item = self
    var tower: Tower = itm.get_carrier()

    tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, tower.get_gold_cost() * 0.0001)
