extends Tower


var gex_rage_buff: BuffType
var gex_rage_buff_15: BuffType
var gex_rage_buff_25: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {trigger_chance = 0.14, buff_level = 0, buff_level_add = 2, duration = 4.0, duration_add = 0.08},
		2: {trigger_chance = 0.15, buff_level = 50, buff_level_add = 3, duration = 5.0, duration_add = 0.10},
		3: {trigger_chance = 0.16, buff_level = 100, buff_level_add = 4, duration = 6.0, duration_add = 0.12},
	}


func get_extra_tooltip_text() -> String:
	var trigger_chance: String = Utils.format_percent(_stats.trigger_chance, 2)
	var duration: String = Utils.format_float(_stats.duration, 2)
	var duration_add: String = Utils.format_float(_stats.duration_add, 2)
	var attackspeed: String = Utils.format_percent(1.5 + 0.01 * _stats.buff_level, 2)
	var attackspeed_add: String = Utils.format_percent(0.01 * _stats.buff_level_add, 2)

	var text: String = ""

	text += "[color=GOLD]Rampage[/color]\n"
	text += "Has a %s chance on attack to go into a rampage for %s seconds. While in rampage, it has +%s attackspeed, +25%% critical strike chance and +75%% critical strike damage. Cannot retrigger while in rampage!\n" % [trigger_chance, duration, attackspeed]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s sec duration\n" % duration_add
	text += "+%s attackspeed\n" % attackspeed_add
	text += "+1 multicrit at lvl 15 and 25\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.20, 0.0)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 1.5, 0.01)
	m.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.25, 0.0)
	m.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.75, 0.0)
	gex_rage_buff = BuffType.new("gex_rage_buff", 0, 0, true, self)
	gex_rage_buff.set_buff_modifier(m)
	gex_rage_buff.set_buff_icon("@@0@@")
	gex_rage_buff.set_stacking_group("gex_rage")
	gex_rage_buff.set_buff_tooltip("Title\nDescription.")

	var m_15: Modifier = Modifier.new()
	m_15.add_modification(Modification.Type.MOD_ATTACKSPEED, 1.5, 0.0)
	m_15.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.25, 0.0)
	m_15.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.75, 0.0)
	m_15.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)
	gex_rage_buff_15 = BuffType.new("gex_rage_buff_15", 0, 0, true, self)
	gex_rage_buff_15.set_buff_modifier(m_15)
	gex_rage_buff_15.set_buff_icon("@@0@@")
	gex_rage_buff_15.set_stacking_group("gex_rage")
	gex_rage_buff_15.set_buff_tooltip("Title\nDescription.")

	var m_25: Modifier = Modifier.new()
	m_25.add_modification(Modification.Type.MOD_ATTACKSPEED, 1.5, 0.0)
	m_25.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.25, 0.0)
	m_25.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.75, 0.0)
	m_15.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 2.0, 0.0)
	gex_rage_buff_25 = BuffType.new("gex_rage_buff_25", 0, 0, true, self)
	gex_rage_buff_25.set_buff_modifier(m_25)
	gex_rage_buff_25.set_buff_icon("@@0@@")
	gex_rage_buff_25.set_stacking_group("gex_rage")
	gex_rage_buff_25.set_buff_tooltip("Title\nDescription.")


func on_attack(_event: Event):
	var tower: Tower = self

	if !tower.calc_chance(_stats.trigger_chance):
		return

	var lvl: int = tower.get_level()

#	Do not allow retriggering while the furbolg is raged
	if tower.get_buff_of_group("gex_rage") == null:
		var buff_type: BuffType
		if lvl < 15:
			buff_type = gex_rage_buff
		elif lvl < 25:
			buff_type = gex_rage_buff_15
		else:
			buff_type = gex_rage_buff_25
		
		buff_type.apply_custom_timed(tower, tower, _stats.buff_level + lvl * _stats.buff_level_add, _stats.duration + _stats.duration_add * lvl)
