extends TowerBehavior


var golden_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_income = 0.05, buff_duration = 10, mod_bounty_gain = 0.40, gold_per_cast = 5},
		2: {mod_income = 0.10, buff_duration = 12, mod_bounty_gain = 0.60, gold_per_cast = 7},
	}


const AUTOCAST_RANGE: float = 400
const BUFF_DURATION_ADD: float = 0.4
const MOD_BOUNTY_GAIN_ADD: float = 0.006


func get_ability_info_list() -> Array[AbilityInfo]:
	var mod_income: String = Utils.format_percent(_stats.mod_income, 2)
	
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Multiply Gold"
	ability.description_short = "This tower increases the gold income of the player.\n"
	ability.description_full = "This tower increases the gold income of the player by %s.\n" % mod_income
	list.append(ability)

	return list


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


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Increases bounty gain of a nearby tower and gives gold to player.\n"

	return text


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Golden Influence", 400, TargetType.new(TargetType.TOWERS))]


func tower_init():
	golden_bt = BuffType.new("golden_bt", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.0, 0.001)
	golden_bt.set_buff_modifier(mod)
	golden_bt.set_buff_icon("res://Resources/Textures/GenericIcons/holy_grail.tres")
	golden_bt.set_buff_tooltip("Golden Influence\nIncreases bounty gained.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Golden Influence"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://Resources/Textures/UI/Icons/gold_icon.tres"
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
	autocast.buff_type = golden_bt
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


func on_autocast(event: Event):
	var level: int = tower.get_level()
	var buff_level: int = int((_stats.mod_bounty_gain + MOD_BOUNTY_GAIN_ADD * level) * 1000)
	var buff_duration: float = _stats.buff_duration + BUFF_DURATION_ADD * level
	golden_bt.apply_custom_timed(tower, event.get_target(), buff_level, buff_duration)
	tower.get_player().give_gold(_stats.gold_per_cast, tower, true, true)


func on_create(_preceding: Tower):
	tower.get_player().modify_income_rate(_stats.mod_income)


func on_destruct():
	tower.get_player().modify_income_rate(-_stats.mod_income)
