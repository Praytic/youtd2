extends ItemBehavior


var multiboard: MultiboardValues


func load_triggers(triggers: BuffType):
	triggers.add_periodic_event(periodic, 15)


func item_init():
	multiboard = MultiboardValues.new(1)
	var gold_found_label: String = tr("H12F")
	multiboard.set_key(0, gold_found_label)


func on_create():
	item.user_int = 0


func on_tower_details() -> MultiboardValues:
	var gold_found_text: String = Utils.format_float(item.user_int, 0)
	multiboard.set_value(0, gold_found_text)

	return multiboard


func periodic(_event: Event):
	var tower: Tower = item.get_carrier()
	var target_effect: int

	target_effect = Effect.create_scaled("res://src/effects/ancient_protector_missile.tscn", tower.get_position_wc3(), 0, 2)
	Effect.set_lifetime(target_effect, 0.1)
	
	if tower.calc_chance(0.40 + tower.get_level() * 0.02):
		CombatLog.log_item_ability(item, null, "Mining Success")
		
		if tower.get_level() < 25:
			tower.get_player().give_gold(3, tower, false, true)
			item.user_int = item.user_int + 3
		else:
			tower.get_player().give_gold(4, tower, false, true)
			item.user_int = item.user_int + 4
	else:
		CombatLog.log_item_ability(item, null, "Mining Fail")
