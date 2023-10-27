# Bloodthirsty Wheel of Fortune
extends Item


var slotMachineMB: MultiboardValues


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Wheel of Fortune[/color]\n"
	text += "With every kill there is a 25% chance to spin the wheel. Every spin will either increase (66% fixed chance) or decrease (33% fixed chance) the item find bonus by 4%. Total range: -24% to +48%. The bonus is bound to the item.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func item_init():
	slotMachineMB = MultiboardValues.new(1)
	slotMachineMB.set_key(0, "Wheel of Fortune Bonus")


func on_create():
	var itm: Item = self
	itm.user_real = 0.0


func on_drop():
	var itm: Item = self
	if itm.user_real != 0.0:
		itm.get_carrier().modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, -1 * itm.user_real)


func on_pickup():
	var itm: Item = self
	if itm.user_real != 0.0:
		itm.get_carrier().modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, itm.user_real)


func on_kill(_event: Event):
	var itm: Item = self
	var t: Tower
	t = itm.get_carrier()

	if t.calc_chance(0.25):
		if Utils.rand_chance(0.33):
			if itm.user_real >= -0.20:
				itm.user_real = itm.user_real - 0.04
				t.modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, -0.04)
				t.get_player().display_small_floating_text("Item Chance Lowered!", t, 255, 0, 0, 30)
		else:
			if itm.user_real <= 0.44:
				itm.user_real = itm.user_real + 0.04
				t.modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.04)
				t.get_player().display_small_floating_text("Item Chance Raised!", t, 0, 0, 255, 30)


func on_tower_details() -> MultiboardValues:
	var itm: Item = self
	slotMachineMB.set_value(0, Utils.format_percent_add_color(itm.user_real, 0))

	return slotMachineMB
