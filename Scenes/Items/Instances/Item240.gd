# Mini Furbolg
extends Item

var BT: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Rampage[/color]\n"
	text += "On each attack the carrier has a 14% attack speed adjusted chance to go into a rampage increasing its attack speed by 25%, multicrit count by 1, crit damage by x0.40 and crit chance by 5% for 4 seconds. Can't retrigger during the buff.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.08 seconds duration\n"
	text += "+0.4% attack speed\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack, 1.0, 0.0)


func item_init():
	var m: Modifier = Modifier.new() 
	m.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.00, 0.0) 
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.25, 0.0) 
	m.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.05, 0.0) 
	m.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.40, 0.0) 
	BT = BuffType.new("item240_BT", 4, 0, true, self)
	BT.set_buff_icon("@@0@@")
	BT.set_buff_modifier(m) 
	BT.set_buff_tooltip("Rampage\nThis unit is on a Rampage; it has increased attack speed, multi crit count, critical damage and critical chance.")


func on_attack(event: Event):
	var itm: Item = self
	var tower: Tower = itm.get_carrier()

	if !(tower.get_buff_of_type(BT) != null) && tower.calc_chance(0.14 * tower.get_base_attack_speed()):
		BT.apply(tower, tower, tower.get_level())