extends Tower


var sir_frost_glacier: BuffType
var cb_stun: BuffType


func _get_tier_stats() -> Dictionary:
	return {
		1: {slow_value = 70, extra_damage = 100, damage_and_stun_chance = 2, stun_duration = 0.8},
		2: {slow_value = 100, extra_damage = 520, damage_and_stun_chance = 3, stun_duration = 0.9},
		3: {slow_value = 130, extra_damage = 1300, damage_and_stun_chance = 4, stun_duration = 1.0},
		4: {slow_value = 160, extra_damage = 2150, damage_and_stun_chance = 5, stun_duration = 1.1},
	}



func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(self, "on_damage", 1.0, 0.0)


func tower_init():
	var m: Modifier = Modifier.new()
	sir_frost_glacier = BuffType.new("sir_frost_glacier", 0, 0, false)
	sir_frost_glacier.set_buff_icon("@@0@@")
	m.add_modification(Modification.Type.MOD_MOVESPEED, 0, -0.001)
	sir_frost_glacier.set_buff_modifier(m)

	cb_stun = CbStun.new("cb_stun", 0, 0, false)


func on_damage(event: Event):
	var tower: Tower = self

	var creep: Unit = event.get_target()

	sir_frost_glacier.apply_custom_timed(tower, creep, _stats.slow_value * (1 + tower.get_level() / 20.0), 3)
	Utils.display_floating_text_x(
		str(int(tower.user_int)) + "% Chance", tower, 50, 150, 255, 255, 0.05, 2, 3)

	if tower.calc_chance(tower.user_int * 0.01) == true && !event.get_target().is_immune():
		cb_stun.apply_only_timed(tower, event.get_target(), 0.8)
		tower.do_spell_damage(creep, _stats.extra_damage * (1 + tower.get_level() * 0.02), tower.calc_spell_crit_no_bonus())
		tower.user_int = _stats.damage_and_stun_chance
	else:
		tower.user_int = tower.user_int + _stats.damage_and_stun_chance


func on_create():
	var tower: Tower = self

	tower.user_int = _stats.damage_and_stun_chance
