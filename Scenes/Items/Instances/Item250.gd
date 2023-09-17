# Crit Blade
extends Item


var crit_blade_multiboard: MultiboardValues


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Critical Accumulation[/color]\n"
	text += "On attack, increases critical strike chance by 2% up to a maximum of 40%. The bonus is lost when a critical strike is made. The bonus is bound to the item.\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.8, 0.0)


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	crit_blade_multiboard = MultiboardValues.new(1)
	crit_blade_multiboard.set_key(0, "Crit Gained")


func on_attack(_event: Event):
	var itm: Item = self

	if (itm.get_carrier().get_number_of_crits() > 0):
		itm.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, -itm.user_real)
		itm.user_real = 0
	else:
		if itm.user_real < 0.40:
			itm.user_real = itm.user_real + 0.02
			itm.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.02)


func on_create():
	var itm: Item = self
	itm.user_real = 0.00


func on_drop():
	var itm: Item = self
	itm.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, -itm.user_real)


func on_pickup():
	var itm: Item = self
	itm.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, itm.user_real)


func on_tower_details() -> MultiboardValues:
	var itm: Item = self
	var crit_chance_bonus_text: String = Utils.format_percent(itm.user_real, 0)
	crit_blade_multiboard.set_value(0, crit_chance_bonus_text)

	return crit_blade_multiboard
