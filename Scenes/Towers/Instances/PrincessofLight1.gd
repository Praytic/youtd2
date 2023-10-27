extends Tower


var boekie_extract_exp_bt: BuffType
var boekie_channel_energy_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {extract_exp = 1, extract_exp_add = 0.05, channel_exp = 1, channel_mod_dmg = 0.15, channel_buff_duration = 10},
		2: {extract_exp = 2, extract_exp_add = 0.10, channel_exp = 2, channel_mod_dmg = 0.20, channel_buff_duration = 12},
	}


const EXTRACT_CHANCE: float = 0.33
const EXTRACT_DURATION: float = 10.0
const EXTRACT_COUNT: int = 10
const EXTRACT_COUNT_ADD: int = 1
const CHANNEL_MOD_DMG_ADD: float = 0.005
const CHANNEL_BUFF_DURATION_ADD: float = 0.1
const CHANNEL_STACK_COUNT: int = 15



func get_ability_description() -> String:
	var channel_exp: String = Utils.format_float(_stats.channel_exp, 2)
	var channel_mod_dmg: String = Utils.format_percent(_stats.channel_mod_dmg, 2)
	var channel_mod_dmg_add: String = Utils.format_percent(CHANNEL_MOD_DMG_ADD, 2)
	var channel_buff_duration: String = Utils.format_float(_stats.channel_buff_duration, 2)
	var channel_buff_duration_add: String = Utils.format_float(CHANNEL_BUFF_DURATION_ADD, 2)
	var channel_stack_count: String = Utils.format_float(CHANNEL_STACK_COUNT, 2)

	var text: String = ""

	text += "[color=GOLD]Channel Energy[/color]\n"
	text += "Whenever this tower is hit by a friendly spell, the caster of that spell will be granted %s experience and this tower will gain %s bonus damage for %s seconds. This effect stacks up to %s times, but new stacks will not refresh the duration of olds ones.\n" % [channel_exp, channel_mod_dmg, channel_buff_duration, channel_stack_count]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % channel_mod_dmg_add
	text += "+%s seconds duration\n" % channel_buff_duration_add

	return text


func get_autocast_description() -> String:
	var extract_chance: String = Utils.format_percent(EXTRACT_CHANCE, 2)
	var extract_exp: String = Utils.format_float(_stats.extract_exp, 2)
	var extract_exp_add: String = Utils.format_float(_stats.extract_exp_add, 2)
	var extract_duration: String = Utils.format_float(EXTRACT_DURATION, 2)
	var extract_count: String = Utils.format_float(EXTRACT_COUNT, 2)
	var extract_count_add: String = Utils.format_float(EXTRACT_COUNT_ADD, 2)

	var text: String = ""

	text += "Casts a buff on a creep. Towers that damage this creep have a %s chance to extract %s experience. Buff lasts %s seconds or until %s extractions occur.\n" % [extract_chance, extract_exp, extract_duration, extract_count]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s experience\n" % extract_exp_add
	text += "+%s extraction\n" % extract_count_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_spell_targeted(on_spell_target)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, 2.0)


func tower_init():
	boekie_extract_exp_bt = BuffType.new("boekie_extract_exp_bt", EXTRACT_DURATION, 0, false, self)
	boekie_extract_exp_bt.add_event_on_damaged(boekie_extract_exp_bt_on_damaged)
	boekie_extract_exp_bt.set_buff_icon("@@0@@")
	boekie_extract_exp_bt.set_buff_tooltip("Extract Experience\nThis unit is affected by Extract Experience; it has a chance to grant extra experience on damage.")

	boekie_channel_energy_bt = BuffType.new("boekie_channel_energy_bt", -1, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.001)
	boekie_channel_energy_bt.set_buff_modifier(mod)
	boekie_channel_energy_bt.set_buff_icon("@@1@@")
	boekie_channel_energy_bt.set_buff_tooltip("Channel Energy\nThis tower is under the effect of Channel Energy; it deals extra damage.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Extract Experience"
	autocast.description = get_autocast_description()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 3
	autocast.cast_range = 1000
	autocast.auto_range = 1000
	autocast.cooldown = 5
	autocast.mana_cost = 20
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = boekie_extract_exp_bt
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_spell_target(event: Event):
	var tower: Tower = self
	var caster: Unit = event.get_target()
	var buff: Buff = tower.get_buff_of_type(boekie_channel_energy_bt)
	var tower_level: int = tower.get_level()
	var buff_level: int = int((_stats.channel_mod_dmg + CHANNEL_MOD_DMG_ADD * tower_level) * 1000)
	var stack_duration: float = _stats.channel_buff_duration + CHANNEL_BUFF_DURATION_ADD * tower_level

	if !caster is Tower:
		return

	caster.add_exp(1)

	if buff == null:
		buff = boekie_channel_energy_bt.apply(tower, tower, buff_level)
		buff.user_int = 1
	else:
		var reached_max_stacks: bool = buff.user_int >= CHANNEL_STACK_COUNT
		if reached_max_stacks:
			return

		buff.user_int += 1
		buff.set_power(buff.get_power() + buff_level)

	await get_tree().create_timer(stack_duration).timeout

	if Utils.unit_is_valid(tower):
		buff = tower.get_buff_of_type(boekie_channel_energy_bt)

		if buff == null:
			return

		if buff.user_int <= 1:
			buff.remove_buff()
		else:
			buff.user_int -= 1
			buff.set_power(buff.get_power() - buff_level)


func on_autocast(event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var buff: Buff = boekie_extract_exp_bt.apply(tower, event.get_target(), level)
	var extraction_count: int = EXTRACT_COUNT + EXTRACT_COUNT_ADD * level
	buff.user_int = extraction_count


func boekie_extract_exp_bt_on_damaged(event: Event):
	var tower: Tower = self
	var buff: Buff = event.get_buff()
	var exp_gain: float = _stats.extract_exp + buff.get_level() * _stats.extract_exp_add
	var extract_count: int = buff.user_int

	if !tower.calc_chance(EXTRACT_CHANCE):
		return

	if extract_count > 0:
		event.get_target().add_exp(exp_gain)
		buff.user_int -= 1
	else:
		buff.remove_buff()
