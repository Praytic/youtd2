extends Tower


var drol_tundraStalker: BuffType
var drol_tundraStalkerValues: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {frenzy_max_bonus = 1.0, buff_level = 0, spell_damage = 50, spell_damage_add = 2},
		2: {frenzy_max_bonus = 1.125, buff_level = 1, spell_damage = 100, spell_damage_add = 4},
		3: {frenzy_max_bonus = 1.25, buff_level = 2, spell_damage = 200, spell_damage_add = 8},
		4: {frenzy_max_bonus = 1.375, buff_level = 3, spell_damage = 400, spell_damage_add = 16},
		5: {frenzy_max_bonus = 1.5, buff_level = 4, spell_damage = 600, spell_damage_add = 24},
	}


func get_extra_tooltip_text() -> String:
	var frenzy_max_bonus: String = Utils.format_percent(_stats.frenzy_max_bonus, 2)

	var text: String = ""

	text += "[color=GOLD]Frenzy[/color]\n"
	text += "Each time Ice Claw is cast, attackspeed is increased by 0.5%% permanently. This has a maximum of %s attack speed increase.\n" % frenzy_max_bonus

	return text


func get_ice_claw_description() -> String:
	var spell_damage: String = Utils.format_float(_stats.spell_damage, 2)
	var spell_damage_add: String = Utils.format_float(_stats.spell_damage_add, 2)
	var slow_amount: String = Utils.format_percent(0.2 + 0.05 * get_tier(), 2)

	var text: String = ""

	text += "Ravages a target creep in 850 range, causing it to suffer %s spell damage per second and be slowed by %s. Effect lasts 5 seconds.\n" % [spell_damage, slow_amount]
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spell damage per second\n" % spell_damage_add
	text += "+0.2 second duration\n"

	return text


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.0, 0.04)


func on_autocast(event: Event):
	var tower: Tower = self

	if tower.user_real < _stats.frenzy_max_bonus:
		tower.user_real = tower.user_real + 0.005
		tower.modify_property(Modification.Type.MOD_ATTACKSPEED, 0.005)

	SFX.sfx_at_unit("FrostBoltMissile.mdl", event.get_target())
	event.get_target().set_visual_modulate(Color8(100, 100, 255, 255))
	drol_tundraStalker.apply_custom_timed(tower, event.get_target(), _stats.buff_level, 5 + 0.2 * tower.get_level()).user_real = _stats.spell_damage + _stats.spell_damage_add * tower.get_level()


func drol_f_tundraStalker(event: Event):
	var b: Buff = event.get_buff()
	b.get_caster().do_spell_damage(b.get_buffed_unit(), b.user_real, b.get_caster().calc_spell_crit_no_bonus())


func drol_fade_tundraStalker(event: Event):
	var b: Buff = event.get_buff()
	b.get_buffed_unit().set_visual_modulate(Color.WHITE)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_MOVESPEED, -0.2, -0.05)

	drol_tundraStalker = BuffType.new("drol_tundraStalker", 5, 0.2, false, self)
	drol_tundraStalker.set_buff_modifier(m)
	
	drol_tundraStalker.set_buff_icon("@@0@@")
	drol_tundraStalker.add_periodic_event(drol_f_tundraStalker, 1)
	drol_tundraStalker.add_event_on_cleanup(drol_fade_tundraStalker)

	drol_tundraStalker.set_buff_tooltip("Ice Claw\nThis unit is suffering periodic damage and has reduced move speed.")

	drol_tundraStalkerValues = MultiboardValues.new(1)
	drol_tundraStalkerValues.set_key(0, "Speed Bonus")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Ice Claw\n"
	autocast.description = get_ice_claw_description()
	autocast.icon = "res://Resources/Textures/gold.tres"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 1
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.cast_range = 850
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 2
	autocast.is_extended = false
	autocast.mana_cost = 10
	autocast.buff_type = drol_tundraStalker
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.auto_range = 850
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_create(preceding: Tower):
	var tower: Tower = self

	if preceding != null && preceding.get_family() == tower.get_family():
		tower.user_real = preceding.user_real
		tower.modify_property(Modification.Type.MOD_ATTACKSPEED, preceding.user_real)
	else:
		tower.user_real = 0


func on_tower_details() -> MultiboardValues:
	var tower: Tower = self

	drol_tundraStalkerValues.set_value(0, str(int(tower.user_real * 100)) + "%")
	return drol_tundraStalkerValues
