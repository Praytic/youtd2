# Soul Collector's Scythe
extends Item


var hokkei_critbonusMB: MultiboardValues


func get_ability_description() -> String:
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


func on_kill(_event: Event):
	var itm: Item = self

	if itm.user_real < 3:
		itm.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.005)
		itm.user_real = itm.user_real + 0.005


func on_tower_details() -> MultiboardValues:
	var itm: Item = self
	var crit_damage_bonus_text: String = "x" + Utils.format_float(itm.user_real, 3)
	hokkei_critbonusMB.set_value(0, crit_damage_bonus_text)

	return hokkei_critbonusMB
