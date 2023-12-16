extends Tower


var drol_phantomBuff: BuffType
var drol_phantom_st: SpellType
var drol_phantom_st_2: SpellType


func get_tier_stats() -> Dictionary:
	return {
		1: {attackspeed = 0.10, buff_level = 0, user_real_base = 0, user_real_add = 1},
		2: {attackspeed = 0.15, buff_level = 5, user_real_base = 50, user_real_add = 3},
		3: {attackspeed = 0.20, buff_level = 10, user_real_base = 125, user_real_add = 6},
		4: {attackspeed = 0.25, buff_level = 15, user_real_base = 225, user_real_add = 10},
		5: {attackspeed = 0.30, buff_level = 20, user_real_base = 425, user_real_add = 18},
	}


func get_wind_shear_description() -> String:
	var attackspeed: String = Utils.format_percent(_stats.attackspeed, 2)
	var chain_damage: String = Utils.format_float(100 * (1.0 + _stats.user_real_base * 0.04), 2)
	var chain_damage_add: String = Utils.format_float(100 * _stats.user_real_add * 0.04, 2)

	var text: String = ""

	text += "Increases the attackspeed of a tower in 300 range by %s and gives it a 25%% attackspeed adjusted chance to cast a chain of lightning which deals %s initial spelldamage and hits up to 3 targets dealing 25%% less damage each bounce. Effect lasts for 5 seconds.\n" % [attackspeed, chain_damage]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% attackspeed\n"
	text += "+%s spelldamage\n" % chain_damage_add
	text += "+1 target at level 20\n"
	text += "+0.1 sec duration\n"

	return text


func get_wind_shear_description_short() -> String:
	var text: String = ""

	text += "Increases the attackspeed of a tower and gives it a chance to cast chainlightning.\n"

	return text


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.00, 0.1)


func phantom_attack(event: Event):
	var b: Buff = event.get_buff()

	var twr: Tower = b.get_buffed_unit()

	if b.get_caster().get_level() < 20:
		if twr.calc_chance(0.25 * twr.get_base_attack_speed()):
			CombatLog.log_ability(twr, event.get_target(), "Wind Shear Bonus")

			drol_phantom_st.target_cast_from_caster(twr, event.get_target(), 1.0 + b.user_real * 0.04, twr.calc_spell_crit_no_bonus())
	else:
		if twr.calc_chance(0.25 * twr.get_base_attack_speed()):
			CombatLog.log_ability(twr, event.get_target(), "Wind Shear Super Bonus")
			
			drol_phantom_st_2.target_cast_from_caster(twr, event.get_target(), 1.0 + b.user_real * 0.04, twr.calc_spell_crit_no_bonus())


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, _stats.attackspeed, 0.01)
	
	drol_phantomBuff = BuffType.new("drol_phantomBuff", 5.0, 0.1, true, self)
	
	drol_phantomBuff.set_buff_modifier(m)
	
	drol_phantomBuff.set_buff_icon("@@2@@")
	
	drol_phantomBuff.add_event_on_attack(phantom_attack)
	
	drol_phantom_st = SpellType.new('@@0@@', "chainlightning", 5.0, self)
	drol_phantom_st.set_source_height(40.0)
	
	drol_phantom_st_2 = SpellType.new('@@1@@', "chainlightning", 5.0, self)
	drol_phantom_st_2.set_source_height(40.0)

	drol_phantomBuff.set_buff_tooltip("Wind Shear\nThis unit is affected by Wind Shear; it has increased attack speed and it has a chance to cast a chain of lightning on attack.")

	drol_phantom_st = SpellType.new("@@0@@", "chainlightning", 5.00, self)
	drol_phantom_st.data.chain_lightning.damage = 100
	drol_phantom_st.data.chain_lightning.damage_reduction = 0.25
	drol_phantom_st.data.chain_lightning.chain_count = 3

	drol_phantom_st_2 = SpellType.new("@@0@@", "chainlightning", 5.00, self)
	drol_phantom_st_2.data.chain_lightning.damage = 100
	drol_phantom_st_2.data.chain_lightning.damage_reduction = 0.25
	drol_phantom_st_2.data.chain_lightning.chain_count = 4

	var autocast: Autocast = Autocast.make()
	autocast.title = "Wind Shear"
	autocast.description = get_wind_shear_description()
	autocast.description_short = get_wind_shear_description_short()
	autocast.icon = "res://Resources/Textures/UI/Icons/gold_icon.tres"
	autocast.caster_art = ""
	autocast.target_art = "Abilities/Spells/Items/AIlm/AIlmTarget.mdl"
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.target_self = true
	autocast.cooldown = 3
	autocast.is_extended = false
	autocast.mana_cost = 15
	autocast.buff_type = drol_phantomBuff
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.cast_range = 300
	autocast.auto_range = 300
	autocast.handler = on_autocast

	add_autocast(autocast)


func on_autocast(event: Event):
	var tower: Tower = self

	drol_phantomBuff.apply_custom_timed(tower, event.get_target(), tower.get_level() + _stats.buff_level, 5.0 + tower.get_level() * 0.1).user_real = tower.get_level() * _stats.user_real_add + _stats.user_real_base
