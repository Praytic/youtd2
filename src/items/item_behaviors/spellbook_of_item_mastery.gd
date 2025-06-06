extends ItemBehavior


var multiboard: MultiboardValues


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_periodic_event(periodic, 5)


func item_init():
	multiboard = MultiboardValues.new(3)
	var waves_left_label: String = tr("L3GS")
	var item_quality_label: String = tr("L71R")
	var item_chance_label: String = tr("SK6C")
	multiboard.set_key(0, waves_left_label)
	multiboard.set_key(1, item_quality_label)
	multiboard.set_key(2, item_chance_label)


func on_attack(event: Event):
	var choose: int
	var target: Creep
	var tower: Tower
	var player: Player

	if item.user_int <= 0:
		item.user_int = 15
		
		tower = item.get_carrier()
		player = item.get_player()
		choose = Globals.synced_rng.randi_range(1, 6)

		if choose <= 4:
			target = event.get_target()

		if choose == 1:
			tower.modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, 1)
			target.drop_item(tower, false)
			tower.modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, -1)
			var one_item_text: String = tr("NJ6M")
			player.display_floating_text(one_item_text, tower, Color8(0, 0, 255))
		elif choose == 2:
			tower.modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, 0.5)
			target.drop_item(tower, false)
			target.drop_item(tower, false)
			tower.modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, -0.5)
			var two_items_text: String = tr("VVB4")
			player.display_floating_text(two_items_text, tower, Color8(0, 0, 255))
		elif choose == 3:
			tower.modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, 0.25)
			target.drop_item(tower, false)
			target.drop_item(tower, false)
			target.drop_item(tower, false)
			tower.modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, -0.25)
			var three_items_text: String = tr("MMDP")
			player.display_floating_text(three_items_text, tower, Color8(0, 0, 255))
		elif choose == 4:
			tower.modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, 0.25)
			target.drop_item(tower, false)
			target.drop_item(tower, false)
			tower.modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, -0.25)
			tower.modify_property(ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL, 0.1)
			item.user_real = item.user_real + 0.1
			item.user_real2 = item.user_real2 + 0.1
			var two_items_and_bonus_text: String = tr("MKEI")
			player.display_floating_text(two_items_and_bonus_text, tower, Color8(0, 0, 255))
		elif choose == 5:
			tower.modify_property(ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL, 0.25)
			item.user_real2 = item.user_real2 + 0.25
			var item_chance_text: String = tr("JQ7S")
			player.display_floating_text(item_chance_text, tower, Color8(0, 255, 0))
		elif choose == 6:
			tower.modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, 0.25)
			item.user_real = item.user_real + 0.25
			var item_quality_text: String = tr("M64K")
			player.display_floating_text(item_quality_text, tower, Color8(0, 255, 0))


func on_create():
	item.user_int = 0
	item.user_int2 = item.get_player().get_team().get_level()
	item.user_real = 0
	item.user_real2 = 0


func on_drop():
	var tower: Tower = item.get_carrier()
	tower.modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, -item.user_real)
	tower.modify_property(ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL, -item.user_real2)


func on_pickup():
	var tower: Tower = item.get_carrier()
	tower.modify_property(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL, item.user_real)
	tower.modify_property(ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL, item.user_real2)


func on_tower_details() -> MultiboardValues:
	var waves_left_text: String = Utils.format_float(item.user_int, 2)
	var item_quality_text: String = Utils.format_percent(item.user_real, 0)
	var item_chance_text: String = Utils.format_percent(item.user_real2, 0)
	multiboard.set_value(0, waves_left_text)
	multiboard.set_value(1, item_quality_text)
	multiboard.set_value(2, item_chance_text)
	
	return multiboard


func periodic(_event: Event):
	var level: int = item.get_player().get_team().get_level()

	if item.user_int2 < level:
		item.user_int = item.user_int - (level - item.user_int2)
		item.user_int2 = level
