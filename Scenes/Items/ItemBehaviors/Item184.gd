# Soul Collectors Cloak
extends ItemBehavior


var multiboard: MultiboardValues


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Soul Power[/color]\n"
	text += "Each time the user of this cloak kills a unit, its dps is increased by 10. There is a maximum of 4000 bonus dps. The extra damage is bound to the item.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func item_init():
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "DPS Gained")


func on_create():
	item.user_int = 0


func on_drop():
	item.get_carrier().modify_property(Modification.Type.MOD_DPS_ADD, -item.user_int)


func on_pickup():
	item.get_carrier().modify_property(Modification.Type.MOD_DPS_ADD, item.user_int)


func on_kill(_event: Event):
	if item.user_int < 4000:
		item.get_carrier().modify_property(Modification.Type.MOD_DPS_ADD, 10)
		item.user_int = item.user_int + 10


func on_tower_details() -> MultiboardValues:
	var dps_gained_text: String = Utils.format_float(item.user_int, 0)
	multiboard.set_value(0, dps_gained_text)

	return multiboard
