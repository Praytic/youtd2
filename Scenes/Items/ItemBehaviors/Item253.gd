# Doom's Ensign
extends ItemBehavior


var BT: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Ensign's Touch[/color]\n"
	text += "When the user of this item attacks an enemy it decreases the armor of the target by 10% for 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% armor decrease\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func item_init():
	var m: Modifier = Modifier.new()
	BT = BuffType.new("Item253_BT", 5, 0, false, self)
	m.add_modification(Modification.Type.MOD_ARMOR_PERC, -0.10, -0.006)
	BT.set_buff_modifier(m)
	BT.set_buff_icon("claw.tres")
	BT.set_buff_icon_color(Color.GRAY)
	BT.set_buff_tooltip("Ensign's Touch\nReduces armor.")


func on_damage(event: Event):
	if event.is_main_target():
		BT.apply(item.get_carrier(), event.get_target(), item.get_carrier().get_level())
