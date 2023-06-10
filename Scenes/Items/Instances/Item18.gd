# Enchanted Knives
extends Item


func get_extra_tooltip_text() -> String:
    var text: String = ""

    text += "[color=GOLD]Multishot[/color]\n"
    text += "Attacks up to 3 targets at the same time.\n"

    return text


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.50, 0.0)


func on_drop():
    var itm: Item = self
    var tower: Tower = itm.get_carrier()
    var target_count: int = tower.get_target_count()
    tower._set_target_count(target_count - 3)


func on_pickup():
    var itm: Item = self
    var tower: Tower = itm.get_carrier()
    var target_count: int = tower.get_target_count()
    tower._set_target_count(target_count + 3)
