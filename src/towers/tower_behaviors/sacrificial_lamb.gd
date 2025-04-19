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
		1: {bloodspill_chance_add = 0.002, bloodspill_mod_attack_speed = 0.50, bloodspill_exp = 0.25, sacrifice_dmg_ratio = 0.30},
		2: {bloodspill_chance_add = 0.004, bloodspill_mod_attack_speed = 0.75, bloodspill_exp = 0.50, sacrifice_dmg_ratio = 0.45},
	}

const BLOODSPILL_DMG_LOSS: float = 1.0
const BLOODSPILL_MOD_ATTACKSPEED_ADD: float = 0.01
const BLOODSPILL_CHANCE: float = 0.15
const BLOODSPILL_RANGE: float = 200
const SACRIFICE_RANGE: float = 500
const SACRIFICE_DMG_RATIO_ADD: float = 0.006
const SACRIFICE_DMG_LOSS: float = 1.0
const BUFF_DURATION: float = 6


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	bloodspill_boost_bt = BuffType.new("bloodspill_boost_bt", BUFF_DURATION, 0, true, self)
	var dave_blood_target: Modifier = Modifier.new()
	dave_blood_target.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 0.0, BLOODSPILL_MOD_ATTACKSPEED_ADD)
	bloodspill_boost_bt.set_buff_modifier(dave_blood_target)
	bloodspill_boost_bt.set_buff_icon("res://resources/icons/generic_icons/sprint.tres")
	bloodspill_boost_bt.set_buff_tooltip(tr("YX3K"))

	bloodspill_fatigue_bt = BuffType.new("bloodspill_fatigue_bt", BUFF_DURATION, 0, false, self)
	var dave_blood_altar: Modifier = Modifier.new()
	dave_blood_altar.add_modification(ModificationType.enm.MOD_ATTACKSPEED, -BLOODSPILL_DMG_LOSS, 0.0)
	bloodspill_fatigue_bt.set_buff_modifier(dave_blood_altar)
	bloodspill_fatigue_bt.set_buff_icon("res://resources/icons/generic_icons/bat_mask.tres")
	bloodspill_fatigue_bt.set_buff_tooltip(tr("OOCC"))

	sacrifice_boost_bt = BuffType.new("sacrifice_boost_bt", BUFF_DURATION, 0, true, self)
	sacrifice_boost_bt.set_buff_icon("res://resources/icons/generic_icons/animal_skull.tres")
	sacrifice_boost_bt.add_event_on_cleanup(dave_sacrifice_target_on_cleanup)
	sacrifice_boost_bt.set_buff_tooltip(tr("N984"))

	sacrifice_fatigue_bt = BuffType.new("sacrifice_fatigue_bt", BUFF_DURATION, 0, false, self)
	var dave_sacrifice_altar: Modifier = Modifier.new()
	dave_sacrifice_altar.add_modification(ModificationType.enm.MOD_DAMAGE_ADD_PERC, -SACRIFICE_DMG_LOSS, 0.0)
	sacrifice_fatigue_bt.set_buff_modifier(dave_sacrifice_altar)
	sacrifice_fatigue_bt.set_buff_icon("res://resources/icons/generic_icons/animal_skull.tres")
	sacrifice_fatigue_bt.set_buff_tooltip(tr("LW5F"))


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

	Effect.create_simple_at_unit("res://src/effects/blood_splatter.tscn", tower)

	while true:
		var target: Unit = it.next()

		if target == null:
			break

		if target != tower:
			var buff_level: int = int((_stats.bloodspill_mod_attack_speed * 100 + level) / num_towers)
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
		target.modify_property(ModificationType.enm.MOD_DPS_ADD, mod_dps_add_value)

	sacrifice_fatigue_bt.apply(tower, tower, tower.get_level())


func dave_sacrifice_target_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Tower = buff.get_buffed_unit()
	var mod_dps_add_value: float = buff.user_real
	buffed_tower.modify_property(ModificationType.enm.MOD_DPS_ADD, -mod_dps_add_value)
