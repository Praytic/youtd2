# Toy Boy
extends Item


var BT: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Play With Me![/color]\n"
	text += "Every 10 seconds the Toy Boy forces the tower to play with him, slowing attack speed of the tower by 50% for 2 seconds.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 10)


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.50, 0.01)


func item_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.5, 0.0)
	BT = BuffType.new("Item146_BT", 2.0, 0, false, self)
	BT.set_buff_icon("@@0@@")
	BT.set_buff_modifier(m)
	BT.set_buff_tooltip("Playtime\nThis unit is affected by Toy Boy; it has reduced attack speed.")


func periodic(_event: Event):
	var itm: Item = self
	BT.apply(itm.get_carrier(), itm.get_carrier(), 1)
