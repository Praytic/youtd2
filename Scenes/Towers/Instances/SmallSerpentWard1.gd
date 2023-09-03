extends Tower


var sir_serpent_buff: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {buff_level = 1, buff_power = 100, buff_power_add = 6},
		2: {buff_level = 30, buff_power = 200, buff_power_add = 12},
		3: {buff_level = 60, buff_power = 300, buff_power_add = 18},
		4: {buff_level = 90, buff_power = 400, buff_power_add = 24},
	}


func get_autocast_description() -> String:
	var mod_mana_max: String = Utils.format_percent(_stats.buff_power * 0.001, 2)
	var mod_mana_max_add: String = Utils.format_percent(_stats.buff_power_add * 0.001, 2)
	var mod_mana_regen: String = mod_mana_max
	var mod_mana_regen_add: String = mod_mana_max_add
	var mod_spell_damage: String = Utils.format_percent(_stats.buff_power * 0.0005, 2)
	var mod_spell_damage_add: String = Utils.format_percent(_stats.buff_power_add * 0.0005, 2)

	var text: String = ""

	text += "Increases the target's maximum mana by %s, its mana regeneration by %s and its spell damage by %s. The buff lasts 5 seconds.\n" % [mod_mana_max, mod_mana_regen, mod_spell_damage]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s mana regeneration\n" % mod_mana_regen_add
	text += "+%s mana \n" % mod_mana_max_add
	text += "+%s spell damage\n" % mod_spell_damage_add
	text += "+5 seconds duration at level 25\n"

	return text


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_MANA_PERC, 0.0, 0.001)
	m.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.0, 0.001)
	m.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.0, 0.0005)
	sir_serpent_buff = BuffType.new("sir_serpent_buff", 0, 0.0005, true, self)
	sir_serpent_buff.set_buff_icon("@@0@@")
	sir_serpent_buff.set_buff_modifier(m)
	sir_serpent_buff.set_stacking_group("sir_serpent_buff")
	sir_serpent_buff.set_buff_tooltip("Snake Charm\nThis tower is affected by Snake Charm; it has increased maximum mana, mana regeneration and spell damage.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Snake Charm"
	autocast.description = get_autocast_description()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 1
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.cast_range = 200
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 5
	autocast.is_extended = false
	autocast.mana_cost = 10
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.auto_range = 200
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_autocast(event: Event):
	var tower: Tower = self

	if tower.get_level() < 25:
		sir_serpent_buff.apply_advanced(tower, event.get_target(), _stats.buff_level + tower.get_level(), _stats.buff_power + tower.get_level() * _stats.buff_power_add, 5)
	else:
		sir_serpent_buff.apply_advanced(tower, event.get_target(), _stats.buff_level + tower.get_level(), _stats.buff_power + tower.get_level() * _stats.buff_power_add, 10)
