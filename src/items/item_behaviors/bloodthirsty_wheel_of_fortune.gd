extends ItemBehavior


var multiboard: MultiboardValues


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func item_init():
	multiboard = MultiboardValues.new(1)
	var fortune_bonus_label: String = tr("ILG6")
	multiboard.set_key(0, fortune_bonus_label)


func on_create():
	item.user_real = 0.0


func on_drop():
	if item.user_real != 0.0:
		item.get_carrier().modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, -1 * item.user_real)


func on_pickup():
	if item.user_real != 0.0:
		item.get_carrier().modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, item.user_real)


func on_kill(_event: Event):
	var t: Tower
	t = item.get_carrier()

	if t.calc_chance(0.25):		
		if Utils.rand_chance(Globals.synced_rng, 0.33):
			if item.user_real >= -0.20:
				CombatLog.log_item_ability(item, null, "Lower Item Chance")
				
				item.user_real = item.user_real - 0.04
				t.modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, -0.04)
				t.get_player().display_small_floating_text("Item Chance Lowered!", t, Color8(255, 0, 0), 30)
		else:
			if item.user_real <= 0.44:
				CombatLog.log_item_ability(item, null, "Raise Item Chance")
				
				item.user_real = item.user_real + 0.04
				t.modify_property(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.04)
				t.get_player().display_small_floating_text("Item Chance Raised!", t, Color8(0, 0, 255), 30)


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, Utils.format_percent_add_color(item.user_real, 0))

	return multiboard
