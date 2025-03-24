extends ItemBehavior


var multiboard: MultiboardValues


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func item_init():
	multiboard = MultiboardValues.new(1)
	var kill_count_label: String = tr("UICO")
	multiboard.set_key(0, kill_count_label)


func on_attack(event: Event):
	var tower: Tower = item.get_carrier()
	var creep: Unit = event.get_target()

	if creep.get_size() < CreepSize.enm.CHAMPION && tower.calc_chance((0.0025 + (tower.get_level() * 0.0001)) * tower.get_base_attack_speed()):
		CombatLog.log_item_ability(item, null, "Curse of the Grave")

		tower.kill_instantly(creep)
		Effect.create_simple_at_unit("res://src/effects/death_coil.tscn", creep)
		SFX.sfx_at_unit(SfxPaths.WATER_SLASH, creep)
		item.user_int = item.user_int + 1


func on_create():
#	number of innocent creeps slaughtered mercilessly.
	item.user_int = 0


func on_tower_details() -> MultiboardValues:
	var tombstone_kills_text: String = Utils.format_float(item.user_int, 0)
	multiboard.set_value(0, tombstone_kills_text)
	
	return multiboard
