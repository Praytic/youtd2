extends ItemBehavior


var multiboard: MultiboardValues


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func item_init():
	multiboard = MultiboardValues.new(1)
	var item_quality_label: String = tr("ZF07")
	multiboard.set_key(0, item_quality_label)


func on_create():
	item.user_real = 0.00


func on_drop():
	item.get_carrier().modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, -item.user_real)


func on_pickup():
	item.get_carrier().modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, item.user_real)


func on_kill(_event: Event):
	item.get_carrier().modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, -item.user_real)
	item.user_real = item.user_real + 0.0015
	item.get_carrier().modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, item.user_real)


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, Utils.format_percent(item.user_real, 2))
	return multiboard
