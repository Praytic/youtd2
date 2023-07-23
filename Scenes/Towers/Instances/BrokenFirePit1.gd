extends Tower


var boekie_coals_buff : BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {power = 0, duration = 7.5},
		2: {power = 50, duration = 8.5},
		3: {power = 100, duration = 9.5},
		4: {power = 150, duration = 10.5},
		5: {power = 200, duration = 11.5},
	}


func get_extra_tooltip_text() -> String:
	var bonus_crit: String = String.num((0.15 + _stats.power * 0.001) * 100, 2)
	var duration: String = String.num(_stats.duration, 2)

	var text: String = ""

	text += "[color=GOLD]Hot Coals[/color]\n"
	text += "Whenever this tower kills a creep it gains %s%% bonus crit chance for %s seconds.\n" % [bonus_crit, duration]
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.05 sec duration\n"
	text += "+0.3%% crit chance"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.15, 0.001)
#	0.0 time since I will apply it custom timed
	boekie_coals_buff = BuffType.new("boekie_coals_buff ", 0.0, 0.0, true, self)
	boekie_coals_buff.set_buff_modifier(m)
	boekie_coals_buff.set_buff_icon("@@0@@")
	boekie_coals_buff.set_stacking_group("boekie_coals")
	boekie_coals_buff.set_buff_tooltip("Hot Coals\nThis tower is affected by Hot Coals; it has increased critical chance.")


func on_kill(_event: Event):
	var tower: Tower = self

	var lvl: int = tower.get_level()
	boekie_coals_buff.apply_custom_timed(tower, tower, lvl * 3, _stats.duration + 0.05 * lvl)
