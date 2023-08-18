extends Tower


var sir_area_rooster: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {buff_level_per_stack = 1, buff_power = 70},
		2: {buff_level_per_stack = 2, buff_power = 140},
		3: {buff_level_per_stack = 4, buff_power = 210},
	}


func get_extra_tooltip_text() -> String:
	var dmg_from_fire: String = Utils.format_percent(_stats.buff_power * 0.001, 2)
	var spell_damage: String = Utils.format_float(35 * _stats.buff_level_per_stack, 2)
	var spell_damage_add: String = Utils.format_float(1.4 * _stats.buff_level_per_stack, 2)

	var text: String = ""

	text += "[color=GOLD]Ignite[/color]\n"
	text += "Units damaged by this tower receive %s more damage from fire towers and take %s spell damage every 0.5 seconds for 5 seconds. The damage over time effect stacks.\n" % [dmg_from_fire, spell_damage]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spell damage \n" % spell_damage_add
	text += "+0.05 seconds duration\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	_set_target_count(4)


func sir_area_damage(event: Event):
	var b: Buff = event.get_buff()
	var caster: Tower = b.get_caster()

	caster.do_spell_damage(b.get_buffed_unit(), (35 + caster.get_level() * 1.4) * b.get_level(), caster.calc_spell_crit_no_bonus())


func tower_init():
	var m: Modifier = Modifier.new()
	sir_area_rooster = BuffType.new("sir_area_rooster", 0, 0, false, self)
	sir_area_rooster.set_buff_icon("@@1@@")
	m.add_modification(Modification.Type.MOD_DMG_FROM_FIRE, 0.0, 0.001)
	sir_area_rooster.set_buff_modifier(m)
	sir_area_rooster.add_periodic_event(sir_area_damage, 0.5)
	sir_area_rooster.set_stacking_group("sir_area_rooster")
	sir_area_rooster.set_buff_tooltip("Ignite\nThis unit has been ignited; it will take spell damage over time and will receive extra damage from fire towers.")


func on_damage(event: Event):
	var tower: Tower = self
	var buffyourno: Buff = event.get_target().get_buff_of_group("sir_area_rooster")

	if buffyourno != null:
		tower.user_int = buffyourno.get_level() + _stats.buff_level_per_stack
		tower.user_int2 = max(buffyourno.get_power(), _stats.buff_power)
	else:
		tower.user_int = _stats.buff_level_per_stack
		tower.user_int2 = _stats.buff_power

	sir_area_rooster.apply_advanced(tower, event.get_target(), tower.user_int, tower.user_int2, 5 + tower.get_level() * 0.05)
