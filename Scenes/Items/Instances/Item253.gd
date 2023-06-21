# Doom's Ensign
extends Item


var BT: BuffType


func get_extra_tooltip_text() -> String:
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
	BT.set_buff_icon("@@0@@")
	BT.set_buff_tooltip("Ensign's Touch\nThis unit's armor is decreased.")


func on_damage(event: Event):
	var itm: Item = self

	if event.is_main_target():
		BT.apply(itm.get_carrier(), event.get_target(), itm.get_carrier().get_level())
