# Excalibur
extends ItemBehavior


var Symphony_armorReduce: BuffType


func get_ability_description() -> String:
    var text: String = ""

    text += "[color=GOLD]Power of the Sword[/color]\n"
    text += "Has an equal chance to decrease the armor of the damaged creep by 5 or 10 for 5 seconds.\n"
    text += " \n"
    text += "[color=ORANGE]Level Bonus:[/color]\n"
    text += "+0.2 armor reduction.\n"

    return text


func load_triggers(triggers: BuffType):
    triggers.add_event_on_damage(on_damage)


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.05, 0.0)
    modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.10, 0.0)
    modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.10, 0.0)


func item_init():
    var m: Modifier = Modifier.new()
    m.add_modification(Modification.Type.MOD_ARMOR, 0.0, -0.2)
    Symphony_armorReduce = BuffType.new("Symphony_armorReduce", 5, 0, false, self)
    Symphony_armorReduce.set_buff_modifier(m)
    Symphony_armorReduce.set_buff_icon("letter_omega.tres")
    Symphony_armorReduce.set_buff_icon_color(Color.ORANGE)
    Symphony_armorReduce.set_buff_tooltip("Power of the Sword\nReduces armor.")


func on_damage(event: Event):
    var tower: Tower = item.get_carrier()

    if event.is_main_target() == true:
        if Utils.rand_chance(Globals.synced_rng, 0.5):
            Symphony_armorReduce.apply(tower, event.get_target(), 25 + tower.get_level())
        else:
            Symphony_armorReduce.apply(tower, event.get_target(), 50 + tower.get_level())
