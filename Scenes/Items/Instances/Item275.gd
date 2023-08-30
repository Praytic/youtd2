# Workbench
extends Item


var boekie_itemQualBonus: MultiboardValues


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Improve Item[/color]\n"
	text += "Every kill increases item quality by 0.15%. The quality improvement is bound to the item."

	return text

func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func item_init():
	boekie_itemQualBonus = MultiboardValues.new(1)
	boekie_itemQualBonus.set_key(0, "Workbench")


func on_create():
	var itm: Item = self
	itm.user_real = 0.00


func on_drop():
	var itm: Item = self
	itm.get_carrier().modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -itm.user_real)


func on_pickup():
	var itm: Item = self
	itm.get_carrier().modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, itm.user_real)


func on_kill(_event: Event):
	var itm: Item = self
	itm.get_carrier().modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -itm.user_real)
	itm.user_real = itm.user_real + 0.0015
	itm.get_carrier().modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, itm.user_real)


func on_tower_details() -> MultiboardValues:
	var itm: Item = self
	boekie_itemQualBonus.set_value(0, Utils.format_percent(itm.user_real, 2))
	return boekie_itemQualBonus
