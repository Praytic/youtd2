# Soul Collector's Scythe
extends Item


var hokkei_critbonusMB: MultiboardValues


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Soul Power[/color]\n"
	text += "After each kill, the scythe's critical strike damage is increased by x0.005. Maximum of x3 bonus crit. The bonus is bound to the item.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func item_init():
	hokkei_critbonusMB = MultiboardValues.new(1)
	hokkei_critbonusMB.set_key(0, "Crit Bonus")


func on_create():
	var itm: Item = self
	itm.user_real = 0


func on_drop():
	var itm: Item = self
	itm.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_DAMAGE, -itm.user_real)


func on_pickup():
	var itm: Item = self
	itm.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_DAMAGE, itm.user_real)


func on_kill(event: Event):
	var itm: Item = self

	if itm.user_real < 3:
		itm.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.005)
		itm.user_real = itm.user_real + 0.005


func on_tower_details() -> MultiboardValues:
	var itm: Item = self
	hokkei_critbonusMB.set_value(0, "x" + str(itm.user_real))

	return hokkei_critbonusMB
