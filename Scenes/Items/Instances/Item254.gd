# Distorted Idol
extends Item


# TODO: implement. Complicated script. Disabled until implemented. Maybe implement by adding hidden items that are copied from other items?


func get_extra_tooltip_text() -> String:
    var text: String = ""

    text += "[color=GOLD]Imitation[/color]\n"
    text += "On pick up, this item copies the abilities and modifiers of every other item already on the tower, except other Distorted Idols and use-actives. The effects are lost when this item is dropped, or the carrier is upgraded or replaced.\n"

    return text


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.60, 0.0)
