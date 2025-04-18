extends ItemBehavior


var multiboard: MultiboardValues


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	multiboard = MultiboardValues.new(1)
	var crit_gained_label: String = tr("E3XG")
	multiboard.set_key(0, crit_gained_label)


func on_attack(event: Event):
	if event.get_number_of_crits() > 0:
		item.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, -item.user_real)
		item.user_real = 0
	else:
		if item.user_real < 0.40:
			item.user_real = item.user_real + 0.02
			item.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.02)


func on_create():
	item.user_real = 0.00


func on_drop():
	item.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, -item.user_real)


func on_pickup():
	item.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, item.user_real)


func on_tower_details() -> MultiboardValues:
	var crit_chance_bonus_text: String = Utils.format_percent(item.user_real, 0)
	multiboard.set_value(0, crit_chance_bonus_text)

	return multiboard
