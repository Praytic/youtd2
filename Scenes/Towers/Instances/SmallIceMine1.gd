extends Tower


var maj_ice_nova_slow: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {slow_value = 75, slow_duration = 2.0, aoe_range = 250, aoe_damage = 150, aoe_damage_add = 7.5},
		2: {slow_value = 90, slow_duration = 3.0, aoe_range = 300, aoe_damage = 500, aoe_damage_add = 25},
		3: {slow_value = 110, slow_duration = 4.0, aoe_range = 350, aoe_damage = 1250, aoe_damage_add = 62.5},
		4: {slow_value = 140, slow_duration = 5.0, aoe_range = 400, aoe_damage = 2500, aoe_damage_add = 125},
	}

func get_extra_tooltip_text() -> String:
	var aoe_damage: String = Utils.format_float(_stats.aoe_damage, 0)
	var aoe_range: String = Utils.format_float(_stats.aoe_range, 0)
	var slow_value: String = Utils.format_percent(_stats.slow_value / 1000.0, 1)
	var slow_duration: String = Utils.format_float(_stats.slow_duration, 0)
	var aoe_damage_add: String = Utils.format_float(_stats.aoe_damage_add, 0)


	var text: String = ""

	text += "[color=GOLD]Ice Nova[/color]\n"
	text += "Damaged targets have a 20%% chance to get blasted by an ice nova, dealing %s damage and slowing units in %s range by %s for %s seconds. Has a 30%% bonus chance to crit.\n" % [aoe_damage, aoe_range, slow_value, slow_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4%% chance\n"
	text += "+%s damage\n" % [aoe_damage_add]

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	var m: Modifier = Modifier.new()

	maj_ice_nova_slow = BuffType.new("maj_ice_nova_slow", 0, 0, false, self)
	m.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	maj_ice_nova_slow.set_buff_modifier(m)
	maj_ice_nova_slow.set_buff_icon("@@0@@")
	maj_ice_nova_slow.set_buff_tooltip("Slowed\nThis unit is Slowed; it has reduced movement speed.")


func on_damage(event: Event):
	var tower: Tower = self

	if !tower.calc_chance(0.2 + tower.get_level() * 0.004):
		return

	var targ: Unit = event.get_target()
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), targ, 250)
	var next: Unit

	while true:
		next = it.next()

		if next == null:
			break

		maj_ice_nova_slow.apply_custom_timed(tower, next, 75, 2.0)

	tower.do_spell_damage_aoe_unit(targ, 250, 150 + (tower.get_level() * 7.5), tower.calc_spell_crit(0.3, 0.0), 0)
	SFX.sfx_at_unit("FrostNovaTarget.mdl", targ)
