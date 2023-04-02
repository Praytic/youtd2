extends Tower


var Poisoned_heart: BuffType


func _get_tier_stats() -> Dictionary:
	return {
		1: {bounce_count = 2, posion_damage = 25, posion_damage_add = 1, poison_duration_add = 0.1},
		2: {bounce_count = 3, posion_damage = 75, posion_damage_add = 3, poison_duration_add = 0.2},
		3: {bounce_count = 4, posion_damage = 150, posion_damage_add = 6, poison_duration_add = 0.3},
		4: {bounce_count = 6, posion_damage = 300, posion_damage_add = 12, poison_duration_add = 0.4},
		5: {bounce_count = 8, posion_damage = 625, posion_damage_add = 25, poison_duration_add = 0.5},
	}


func load_specials():
	_set_attack_style_bounce(_stats.bounce_count, 0.0)


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(self, "on_damage", 1.0, 0.0)


func deal_damage(event: Event):
	var b: Buff = event.get_buff()

	var creep: Unit = b.get_buffed_unit()
	var tower: Tower = b.get_caster()
	tower.do_spell_damage(creep, b.user_real, tower.calc_spell_crit_no_bonus())


func tower_init():
	Poisoned_heart = BuffType.new("Poisoned_heart", 9, 0.5, false)
	Poisoned_heart.set_buff_icon("@@0@@")

	Poisoned_heart.add_periodic_event(self, "deal_damage", 1)


func on_damage(event: Event):
	var tower: Tower = self

	var creep: Unit = event.get_target()

	Poisoned_heart.apply_custom_timed(tower, creep, tower.get_level(), 6 + tower.get_level() * _stats.poison_duration_add).user_real = _stats.posion_damage + _stats.posion_damage_add * tower.get_level()
