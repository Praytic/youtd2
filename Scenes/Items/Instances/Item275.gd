# Workbench
extends ItemBehavior


var boekie_itemQualBonus: MultiboardValues


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Improve Item[/color]\n"
	text += "Every kill increases item quality by 0.15%. The quality improvement is bound to the item.\n"

	return text

func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func item_init():
	boekie_itemQualBonus = MultiboardValues.new(1)
	boekie_itemQualBonus.set_key(0, "Workbench")


func on_create():
	item.user_real = 0.00


func on_drop():
	item.get_carrier().modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -item.user_real)


func on_pickup():
	item.get_carrier().modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, item.user_real)


func on_kill(_event: Event):
	item.get_carrier().modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, -item.user_real)
	item.user_real = item.user_real + 0.0015
	item.get_carrier().modify_property(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, item.user_real)


func on_tower_details() -> MultiboardValues:
	boekie_itemQualBonus.set_value(0, Utils.format_percent(item.user_real, 2))
	return boekie_itemQualBonus
