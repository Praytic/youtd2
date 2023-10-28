extends Tower


# NOTE: changed how storm is enabled/disabled. In original
# script it's done using PeriodicEvent. In this script it's
# done using "storm_is_enabled" flag.


var natac_cloudy_temple_aura_bt: BuffType
var natac_cloudy_temple_storm_bt: BuffType
var natac_cloudy_temple_pt: ProjectileType
var multiboard: MultiboardValues

var storm_is_enabled: bool = false
var threshold_for_cloudy_thunderstorm_autocast: float = 1.0
var storm_effect: int = 0
var storm_timeout_counter: int = 0

const storm_mana_reduction_values: Dictionary = {
	CreepSize.enm.MASS: 5,
	CreepSize.enm.NORMAL: 10,
	CreepSize.enm.AIR: 20,
	CreepSize.enm.CHAMPION: 20,
	CreepSize.enm.CHALLENGE_MASS: 13,
	CreepSize.enm.BOSS: 20,
	CreepSize.enm.CHALLENGE_BOSS: 130,
}

func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Cloud of Absorption - Aura[/color]\n"
	text += "Creates a lightning ball if a creep in 1000 range is killed with more damage than needed. The lighting ball absorbs the redundant damage and transfers it to this temple. Every 1 damage absorbed grants 1 mana.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.05 mana per absorbed damage\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Cloud of Absorption - Aura[/color]\n"
	text += "Creates a lightning ball if a creep in range is killed with more damage than needed. The lighting ball absorbs the redundant damage and transfers it to this temple as mana.\n"

	return text


func get_autocast_description_for_cloudy_thunderstorm() -> String:
	var text: String = ""

	text += "Summons a cloudy thunderstorm, which strikes random creeps in 1000 range every 0.4 seconds with lightning. Each strike deals [Current Mana x 0.5] spell damage and costs mana based on the target's size and the damage dealt. The storm ends when this tower's mana falls below 1000, or no creep comes within range for 4 seconds. This ability will activate automatically when this tower's mana reaches a set threshold, as determined by the 'Adjust Autocast Threshold' ability. The autocast cannot be disabled.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.02 damage per current mana\n"

	return text


func get_autocast_description_for_cloudy_thunderstorm_short() -> String:
	var text: String = ""

	text += "Summons a cloudy thunderstorm, which strikes random creeps in range.\n"

	return text


func get_autocast_description_for_adjust_threshold() -> String:
	var text: String = ""

	text += "Use this ability to adjust the percentual mana required for Cloudy Thunderstorm's autocast.\n"

	return text


func get_autocast_description_for_adjust_threshold_short() -> String:
	var text: String = ""

	text += "Use this ability to adjust the percentual mana required for Cloudy Thunderstorm's autocast.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 1000, TargetType.new(TargetType.CREEPS))
	triggers.add_periodic_event(periodic, 0.4)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, 500.0)


func tower_init():
	natac_cloudy_temple_aura_bt = BuffType.create_aura_effect_type("natac_cloudy_temple_aura_bt", false, self)
	natac_cloudy_temple_aura_bt.set_buff_icon("@@1@@")
	natac_cloudy_temple_aura_bt.add_event_on_damaged(natac_cloudy_temple_aura_bt_on_damaged)
	natac_cloudy_temple_aura_bt.set_buff_tooltip("Cloud of Absorption Aura\nThis unit is under the effect of Cloud of Absorption Aura; it will convert any overkill damage to mana for aura giver.")

	natac_cloudy_temple_storm_bt = BuffType.new("natac_cloudy_temple_storm_bt", -1.0, 0.0, false, self)
	natac_cloudy_temple_storm_bt.add_event_on_damaged(natac_cloudy_temple_storm_bt_on_damaged)
	natac_cloudy_temple_storm_bt.set_buff_tooltip("Cloudy Thunderstorm\nThis unit is affected by Cloudy Thunderstorm; it receives periodic damage.")

	natac_cloudy_temple_pt = ProjectileType.create_ranged("FarserrMissile.mdl", 1000 + 100, 500, self)
	natac_cloudy_temple_pt.enable_homing(natac_cloudy_temple_pt_on_hit, 0.0)

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Mana required")

	var autocast1: Autocast = Autocast.make()
	autocast1.title = "Cloudy Thunderstorm"
	autocast1.description = get_autocast_description_for_cloudy_thunderstorm()
	autocast1.description_short = get_autocast_description_for_cloudy_thunderstorm_short()
	autocast1.icon = "res://path/to/icon.png"
	autocast1.caster_art = ""
	autocast1.target_art = ""
	autocast1.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast1.num_buffs_before_idle = 0
	autocast1.cast_range = 0
	autocast1.auto_range = 0
	autocast1.cooldown = 0.01
	autocast1.mana_cost = 1000
	autocast1.target_self = false
	autocast1.is_extended = false
	autocast1.buff_type = null
	autocast1.target_type = TargetType.new(TargetType.TOWERS)
	autocast1.handler = on_autocast_cloud_thunderstorm
	add_autocast(autocast1)

	var autocast2: Autocast = Autocast.make()
	autocast2.title = "Adjust Autocast Threshold"
	autocast2.description = get_autocast_description_for_adjust_threshold()
	autocast2.description_short = get_autocast_description_for_adjust_threshold_short()
	autocast2.icon = "res://path/to/icon.png"
	autocast2.caster_art = ""
	autocast2.target_art = ""
	autocast2.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast2.num_buffs_before_idle = 0
	autocast2.cast_range = 0
	autocast2.auto_range = 0
	autocast2.cooldown = 0.01
	autocast2.mana_cost = 0
	autocast2.target_self = false
	autocast2.is_extended = false
	autocast2.buff_type = null
	autocast2.target_type = TargetType.new(TargetType.TOWERS)
	autocast2.handler = on_autocast_adjust_threshold
	add_autocast(autocast2)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 1000
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 1
	aura.level_add = 1
	aura.power = 1
	aura.power_add = 1
	aura.aura_effect = natac_cloudy_temple_aura_bt
	add_aura(aura)


func on_autocast_cloud_thunderstorm(_event: Event):
	if !storm_is_enabled:
		enable_storm()


func on_autocast_adjust_threshold(_event: Event):
	var tower: Tower = self

	threshold_for_cloudy_thunderstorm_autocast += 0.1
	if threshold_for_cloudy_thunderstorm_autocast > 1.0:
		threshold_for_cloudy_thunderstorm_autocast = 0.0

	var floating_text: String = Utils.format_percent(threshold_for_cloudy_thunderstorm_autocast, 0)
	tower.get_player().display_small_floating_text(floating_text, tower, 155, 155, 255, 40.0)


func on_tower_details() -> MultiboardValues:
	var mana_required: String = Utils.format_percent(threshold_for_cloudy_thunderstorm_autocast, 0)
	multiboard.set_value(0, mana_required)

	return multiboard


func on_destruct():
	if storm_effect != 0:
		Effect.destroy_effect(storm_effect)


func on_unit_in_range(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()

	if !storm_is_enabled && !target.is_immune():
		var threshold_reached: bool = tower.get_mana_ratio() > threshold_for_cloudy_thunderstorm_autocast

		if threshold_reached:
			enable_storm()


func periodic(_event: Event):
	var tower: Tower = self
	var mana: float = tower.get_mana()

#	The next strike will be realeased, if
#	a) The storm is enabled AND
#	b) The tower has still some mana AND
#	c) No timeout is reached
	if storm_is_enabled && mana > 1000 && storm_timeout_counter < 10:
#		Release next strike
		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1000)
		var target: Unit = it.next_random()

		if target != null:
			storm_timeout_counter = 0
			natac_cloudy_temple_storm_bt.apply(tower, target, 1)
			var damage: float = tower.get_mana() * (0.5 + 0.02 * tower.get_level())
			tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
			SFX.sfx_at_unit("MonsoonBoltTarget.mdl", target)
		else:
			storm_timeout_counter += 1
	else:
		storm_is_enabled = false

		if storm_effect != 0:
			Effect.destroy_effect(storm_effect)
			storm_effect = 0

		storm_timeout_counter = 0


# --- Storm Buff Handling ---
func natac_cloudy_temple_storm_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var target: Creep = buff.get_buffed_unit()
#	Calculate how much damage is really dealt
	var dmg_taken: float = min(event.damage, target.get_health())
	var target_size: CreepSize.enm = target.get_size()
	var mana_loss: float = dmg_taken * 0.1 * storm_mana_reduction_values[target_size]

#	Remove mana from the tower according to the damage taken
#	and the size of the creep
	caster.subtract_mana(mana_loss, true)
	buff.remove_buff()


func enable_storm():
	var tower: Tower = self
	
	if storm_is_enabled:
		return

	storm_is_enabled = true
	storm_effect = Effect.create_animated("CloudOfFog.mdl", tower.get_visual_x(), tower.get_visual_y(), 150.0, 0.0)


# --- Aura Buff + Projectile Handling ---
# If a creep with the auras buff is killed, a projectile spawns
# Reaction of a natac_obsorption_AuraBuffType on Damage
func natac_cloudy_temple_aura_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var caster: Unit = buff.get_caster()
	var damage: float = event.damage
	var life: float = target.get_health()

	var target_will_die: bool = damage > life
	var target_is_affected_by_storm: bool = target.get_buff_of_type(natac_cloudy_temple_storm_bt) != null

	if target_will_die && !target_is_affected_by_storm:
		var mana_ball: Projectile = Projectile.create_from_unit_to_unit(natac_cloudy_temple_pt, caster, 0.0, 0.0, target, caster, true, false, false)
		var redundant_damage: float = damage - life
		mana_ball.user_real = redundant_damage


func natac_cloudy_temple_pt_on_hit(projectile: Projectile, tower: Unit):
	if tower == null || !Utils.unit_is_valid(tower):
		return

	var max_mana: float = tower.get_overall_mana()
	var current_mana: float = tower.get_mana()
	var redundant_damage: float = projectile.user_real
	var granted_mana: float = redundant_damage * (1.0 + 0.05 * tower.get_level())

	if granted_mana > 0:
		tower.add_mana(granted_mana)

	var actual_granted_mana: float = min(max_mana - current_mana, granted_mana)
	var floating_text: String = "+%s" % str(int(actual_granted_mana))
	tower.get_player().display_small_floating_text(floating_text, tower, 0, 0, 255, 40)

	var mana_is_full: bool = current_mana + granted_mana >= max_mana

	if !storm_is_enabled && mana_is_full:
		enable_storm()
