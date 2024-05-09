extends TowerBehavior


# NOTE: weird thing about Sacrifice ability. The description
# says: "...to boost the dps of a tower in 500 range by 30%
# of its total damage for 6 seconds". Is it 30% of total
# damage of caster or target? According to original script,
# it's 30% of caster so I reproduced the same behavior.
# 
# But this behavior doesn't make sense. What's the point of
# making caster lose 100% damage so that another tower will
# get a bonus of 30% from caster's damage? Seems like a net
# negative in all cases.
# 
# Would make more sense if it was the other way. Then, if
# this tower casts Sacrifice on a very powerful tower,
# losing 100% of this tower's damage to gain 30% bonus to
# very powerful tower could be a net win.


var sacrifice_boost_bt: BuffType
var sacrifice_fatigue_bt: BuffType
var bloodspill_boost_bt: BuffType
var bloodspill_fatigue_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_mana_regen_add = 0.1, bloodspill_chance_add = 0.002, bloodspill_mod_attackspeed = 0.50, bloodspill_exp = 0.25, sacrifice_dmg_ratio = 0.30},
		2: {mod_mana_regen_add = 0.2, bloodspill_chance_add = 0.004, bloodspill_mod_attackspeed = 0.75, bloodspill_exp = 0.50, sacrifice_dmg_ratio = 0.45},
	}

const BLOODSPILL_DMG_LOSS: float = 1.0
const BLOODSPILL_MOD_ATTACKSPEED_ADD: float = 0.01
const BLOODSPILL_CHANCE: float = 0.15
const BLOODSPILL_RANGE: float = 200
const SACRIFICE_RANGE: float = 500
const SACRIFICE_DMG_RATIO_ADD: float = 0.006
const SACRIFICE_DMG_LOSS: float = 1.0
const BUFF_DURATION: float = 6


func get_ability_info_list() -> Array[AbilityInfo]:
	var bloodspill_dmg_loss: String = Utils.format_percent(BLOODSPILL_DMG_LOSS, 2)
	var bloodspill_mod_attackspeed: String = Utils.format_percent(_stats.bloodspill_mod_attackspeed, 2)
	var bloodspill_mod_attackspeed_add: String = Utils.format_percent(BLOODSPILL_MOD_ATTACKSPEED_ADD, 2)
	var bloodspill_chance: String = Utils.format_percent(BLOODSPILL_CHANCE, 2)
	var bloodspill_chance_add: String = Utils.format_percent(_stats.bloodspill_chance_add, 2)
	var bloodspill_range: String = Utils.format_float(BLOODSPILL_RANGE, 2)
	var bloodspill_exp: String = Utils.format_float(_stats.bloodspill_exp, 2)
	var buff_duration: String = Utils.format_float(BUFF_DURATION, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Blood Spill"
	ability.icon = "res://Resources/Icons/helmets/helmet_06.tres"
	ability.description_short = "On attack, this tower has a chance to lose attack speed and boost the attack speed of nearby towers.\n"
	ability.description_full = "On attack, this tower has a %s chance to lose %s attack speed and boost the attack speed of all towers in %s range by %s, equally divided among them, for %s seconds. Every time it casts Blood Spill, the tower gains %s experience for every other tower affected. Cannot retrigger when the buff is already active.\n" % [bloodspill_chance, bloodspill_dmg_loss, bloodspill_range, bloodspill_mod_attackspeed, buff_duration, bloodspill_exp] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s attack speed\n" % bloodspill_mod_attackspeed_add \
	+ "+%s chance\n" % bloodspill_chance_add
	list.append(ability)

	return list


func get_autocast_description() -> String:
	var sacrifice_dmg_loss: String = Utils.format_percent(SACRIFICE_DMG_LOSS, 2)
	var sacrifice_range: String = Utils.format_float(SACRIFICE_RANGE, 2)
	var sacrifice_dmg_ratio: String = Utils.format_percent(_stats.sacrifice_dmg_ratio, 2)
	var sacrifice_dmg_ratio_add: String = Utils.format_percent(SACRIFICE_DMG_RATIO_ADD, 2)
	var buff_duration: String = Utils.format_float(BUFF_DURATION, 2)

	var text: String = ""

	text += "This tower loses %s of its damage to boost the dps of a tower in %s range by %s of its total damage for %s seconds. This buff has no effect on towers of the same family.\n" % [sacrifice_dmg_loss, sacrifice_range, sacrifice_dmg_ratio, buff_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s bonus damage\n" % sacrifice_dmg_ratio_add

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "This tower loses a portion of its damage to boost the dps of a nearby tower.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, _stats.mod_mana_regen_add)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Sacrifice", 500, TargetType.new(TargetType.TOWERS)), RangeData.new("Blood Spill", 200, TargetType.new(TargetType.TOWERS))]


func tower_init():
	bloodspill_boost_bt = BuffType.new("bloodspill_boost_bt", BUFF_DURATION, 0, true, self)
	var dave_blood_target: Modifier = Modifier.new()
	dave_blood_target.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, BLOODSPILL_MOD_ATTACKSPEED_ADD)
	bloodspill_boost_bt.set_buff_modifier(dave_blood_target)
	bloodspill_boost_bt.set_buff_icon("res://Resources/Icons/GenericIcons/sprint.tres")
	bloodspill_boost_bt.set_buff_tooltip("Blood Spill Boost\nIncreases attack speed.")

	bloodspill_fatigue_bt = BuffType.new("bloodspill_fatigue_bt", BUFF_DURATION, 0, false, self)
	var dave_blood_altar: Modifier = Modifier.new()
	dave_blood_altar.add_modification(Modification.Type.MOD_ATTACKSPEED, -BLOODSPILL_DMG_LOSS, 0.0)
	bloodspill_fatigue_bt.set_buff_modifier(dave_blood_altar)
	bloodspill_fatigue_bt.set_buff_icon("res://Resources/Icons/GenericIcons/bat_mask.tres")
	bloodspill_fatigue_bt.set_buff_tooltip("Blood Spill Fatigue\nReduces attack damage by 100%.")

	sacrifice_boost_bt = BuffType.new("sacrifice_boost_bt", BUFF_DURATION, 0, true, self)
	sacrifice_boost_bt.set_buff_icon("res://Resources/Icons/GenericIcons/animal_skull.tres")
	sacrifice_boost_bt.add_event_on_cleanup(dave_sacrifice_target_on_cleanup)
	sacrifice_boost_bt.set_buff_tooltip("Sacrifice Boost\nIncreases DPS.")

	sacrifice_fatigue_bt = BuffType.new("sacrifice_fatigue_bt", BUFF_DURATION, 0, false, self)
	var dave_sacrifice_altar: Modifier = Modifier.new()
	dave_sacrifice_altar.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, -SACRIFICE_DMG_LOSS, 0.0)
	sacrifice_fatigue_bt.set_buff_modifier(dave_sacrifice_altar)
	sacrifice_fatigue_bt.set_buff_icon("res://Resources/Icons/GenericIcons/animal_skull.tres")
	sacrifice_fatigue_bt.set_buff_tooltip("Sacrifice Fatigue\nReduces attack damage by 100%.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Sacrifice"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://Resources/Icons/furniture/artifact_on_pedestal.tres"
	autocast.caster_art = "CarrionSwarmDamage.mdl"
	autocast.target_art = "DeathPactCaster.mdl"
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 1
	autocast.cast_range = SACRIFICE_RANGE
	autocast.auto_range = SACRIFICE_RANGE
	autocast.cooldown = 6
	autocast.mana_cost = 90
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = sacrifice_boost_bt
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


func on_attack(_event: Event):
	var level: int = tower.get_level()
	var chance: float = BLOODSPILL_CHANCE + _stats.bloodspill_chance_add * level
	var blood_altar_buff: Buff = tower.get_buff_of_type(bloodspill_fatigue_bt)
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), BLOODSPILL_RANGE)
# 	NOTE: subtract 1 to exclude the tower itself
	var num_towers: int = it.count() - 1

	if !Utils.rand_chance(Globals.synced_rng, chance):
		return

	if blood_altar_buff != null:
		return
	
	if num_towers == 0:
		return

	CombatLog.log_ability(tower, null, "Blood Spill")

	SFX.sfx_at_unit("HumanBloodKnight.mdl", tower)

	while true:
		var target: Unit = it.next()

		if target == null:
			break

		if target != tower:
			var buff_level: int = int((_stats.bloodspill_mod_attackspeed * 100 + level) / num_towers)
			bloodspill_boost_bt.apply(tower, target, buff_level)

	bloodspill_fatigue_bt.apply(tower, tower, level)
	var exp_gain: float = _stats.bloodspill_exp * num_towers
	tower.add_exp(exp_gain)


func on_autocast(event: Event):
	var target: Tower = event.get_target()
	var same_family: bool = tower.get_family() == target.get_family()
	var active_buff: Buff = target.get_buff_of_type(sacrifice_boost_bt)

	if same_family:
		return

	if active_buff != null:
		sacrifice_boost_bt.apply(tower, target, 0)
	else:
		var applied_buff: Buff = sacrifice_boost_bt.apply(tower, target, 0)
		var sacrifice_dmg_ratio: float = _stats.sacrifice_dmg_ratio + SACRIFICE_DMG_RATIO_ADD * tower.get_level()
		var mod_dps_add_value: float = tower.get_current_attack_damage_with_bonus() * sacrifice_dmg_ratio
		applied_buff.user_real = mod_dps_add_value
		target.modify_property(Modification.Type.MOD_DPS_ADD, mod_dps_add_value)

	sacrifice_fatigue_bt.apply(tower, tower, tower.get_level())


func dave_sacrifice_target_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Tower = buff.get_buffed_unit()
	var mod_dps_add_value: float = buff.user_real
	buffed_tower.modify_property(Modification.Type.MOD_DPS_ADD, -mod_dps_add_value)
