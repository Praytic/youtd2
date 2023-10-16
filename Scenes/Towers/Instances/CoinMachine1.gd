extends Tower


var boekie_coin_machine_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_income = 0.05, buff_duration = 10, mod_bounty_gain = 0.40, gold_per_cast = 5},
		2: {mod_income = 0.10, buff_duration = 12, mod_bounty_gain = 0.60, gold_per_cast = 7},
	}


const AUTOCAST_RANGE: float = 400
const BUFF_DURATION_ADD: float = 0.4
const MOD_BOUNTY_GAIN_ADD: float = 0.006


func get_extra_tooltip_text() -> String:
	var mod_income: String = Utils.format_percent(_stats.mod_income, 2)

	var text: String = ""

	text += "[color=GOLD]Multiply Gold[/color]\n"
	text += "This tower increases the gold income of the player by %s.\n" % mod_income

	return text


func get_autocast_description() -> String:
	var autocast_range: String = Utils.format_float(AUTOCAST_RANGE, 2)
	var buff_duration: String = Utils.format_float(_stats.buff_duration, 2)
	var buff_duration_add: String = Utils.format_float(BUFF_DURATION_ADD, 2)
	var mod_bounty_gain: String = Utils.format_percent(_stats.mod_bounty_gain, 2)
	var mod_bounty_gain_add: String = Utils.format_percent(MOD_BOUNTY_GAIN_ADD, 2)
	var gold_per_cast: String = Utils.format_float(_stats.gold_per_cast, 2)

	var text: String = ""

	text += "This tower adds a buff to a tower in %s range that lasts %s seconds. The buff increases bounty gain by %s. Everytime this spell is cast you gain %s gold.\n" % [autocast_range, buff_duration, mod_bounty_gain, gold_per_cast]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s seconds duration\n" % buff_duration_add
	text += "+%s bounty gain\n" % mod_bounty_gain_add

	return text


func tower_init():
	boekie_coin_machine_bt = BuffType.new("boekie_coin_machine_bt", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.0, 0.001)
	boekie_coin_machine_bt.set_buff_modifier(mod)
	boekie_coin_machine_bt.set_buff_icon("@@0@@")
	boekie_coin_machine_bt.set_buff_tooltip("Golden Influence\nThis tower is under the Golden Influence; it has increased bounty gain.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Golden Influence"
	autocast.description = get_autocast_description()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = "ResourceEffectTarget.mdl"
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 3
	autocast.cast_range = AUTOCAST_RANGE
	autocast.auto_range = AUTOCAST_RANGE
	autocast.cooldown = 4
	autocast.mana_cost = 20
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = boekie_coin_machine_bt
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_autocast(event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var buff_level: int = int((_stats.mod_bounty_gain + MOD_BOUNTY_GAIN_ADD * level) * 1000)
	var buff_duration: float = _stats.buff_duration + BUFF_DURATION_ADD * level
	boekie_coin_machine_bt.apply_custom_timed(tower, event.get_target(), buff_level, buff_duration)
	tower.get_player().give_gold(_stats.gold_per_cast, tower, true, true)


func on_create(_preceding: Tower):
	var tower: Tower = self
	tower.get_player().modify_income_rate(_stats.mod_income)


func on_destruct():
	var tower: Tower = self
	tower.get_player().modify_income_rate(-_stats.mod_income)
