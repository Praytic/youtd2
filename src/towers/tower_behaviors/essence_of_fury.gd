extends TowerBehavior


var poison_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {poison_damage = 25, poison_damage_add = 1, poison_duration_add = 0.1},
		2: {poison_damage = 75, poison_damage_add = 3, poison_duration_add = 0.2},
		3: {poison_damage = 150, poison_damage_add = 6, poison_duration_add = 0.3},
		4: {poison_damage = 300, poison_damage_add = 12, poison_duration_add = 0.4},
		5: {poison_damage = 625, poison_damage_add = 25, poison_duration_add = 0.5},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func deal_damage(event: Event):
	var b: Buff = event.get_buff()

	var creep: Unit = b.get_buffed_unit()
	tower.do_spell_damage(creep, b.user_real, tower.calc_spell_crit_no_bonus())


func tower_init():
	poison_bt = BuffType.new("poison_bt", 9, 0.5, false, self)
	poison_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")

	poison_bt.add_periodic_event(deal_damage, 1)

	poison_bt.set_buff_tooltip(tr("LSQD"))


func on_damage(event: Event):
	var creep: Unit = event.get_target()

	poison_bt.apply_custom_timed(tower, creep, tower.get_level(), 6 + tower.get_level() * _stats.poison_duration_add).user_real = _stats.poison_damage + _stats.poison_damage_add * tower.get_level()
