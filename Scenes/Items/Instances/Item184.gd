# Soul Collectors Cloak
extends Item

var cedi_dps_cloak_mb: MultiboardValues


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Soul Power[/color]\n"
	text += "Each time the user of this cloak kills a unit, its dps is increased by 10. There is a maximum of 4000 bonus dps. The extra damage is bound to the item.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func item_init():
	cedi_dps_cloak_mb = MultiboardValues.new(1)
	cedi_dps_cloak_mb.set_key(0, "DPS Gained")


func on_create():
	var itm: Item = self
	itm.user_int = 0


func on_drop():
	var itm: Item = self
	itm.get_carrier().modify_property(Modification.Type.MOD_DPS_ADD, -itm.user_int)


func on_pickup():
	var itm: Item = self
	itm.get_carrier().modify_property(Modification.Type.MOD_DPS_ADD, itm.user_int)


func on_kill(_event: Event):
	var itm: Item = self

	if itm.user_int < 4000:
		itm.get_carrier().modify_property(Modification.Type.MOD_DPS_ADD, 10)
		itm.user_int = itm.user_int + 10


func on_tower_details() -> MultiboardValues:
	var itm: Item = self
	cedi_dps_cloak_mb.set_value(0, str(itm.user_int))

	return cedi_dps_cloak_mb
