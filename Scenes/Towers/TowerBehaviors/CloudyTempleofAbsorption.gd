extends TowerBehavior


# NOTE: changed how storm is enabled/disabled. In original
# script it's done using PeriodicEvent. In this script it's
# done using "storm_is_enabled" flag.

# NOTE: original script has a bug where it defines special
# values for challenge sizes in storm_mana_reduction_values
# map but fails to use them because it uses creep.get_size()
# which returns BOSS instead of CHALLENGE_BOSS. Fixed this
# bug by calling creep.get_size_including_challenge_sizes().


var aura_bt: BuffType
var storm_bt: BuffType
var missile_pt: ProjectileType
var multiboard: MultiboardValues

var storm_is_enabled: bool = false
var threshold_for_cloudy_thunderstorm_autocast: float = 1.0
var storm_effect: int = 0
var storm_timeout_counter: int = 0

const AURA_RANGE: int = 1000

const storm_mana_reduction_values: Dictionary = {
	CreepSize.enm.MASS: 5,
	CreepSize.enm.NORMAL: 10,
	CreepSize.enm.AIR: 20,
	CreepSize.enm.CHAMPION: 20,
	CreepSize.enm.CHALLENGE_MASS: 13,
	CreepSize.enm.BOSS: 20,
	CreepSize.enm.CHALLENGE_BOSS: 130,
}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 1000, TargetType.new(TargetType.CREEPS))
	triggers.add_periodic_event(periodic, 0.4)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, 500.0)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	aura_bt.set_buff_icon("res://Resources/Icons/GenericIcons/semi_closed_eye.tres")
	aura_bt.add_event_on_damaged(aura_bt_on_damaged)
	aura_bt.set_buff_tooltip("Cloud of Absorption Aura\nConverts any overkill damage to mana for aura giver.")

	storm_bt = BuffType.new("storm_bt", -1.0, 0.0, false, self)
	storm_bt.add_event_on_damaged(storm_bt_on_damaged)
	storm_bt.set_buff_tooltip("Cloudy Thunderstorm\nDeals damage over time.")

	missile_pt = ProjectileType.create_ranged("FarserrMissile.mdl", 1000 + 100, 500, self)
	missile_pt.enable_homing(missile_pt_on_hit, 0.0)

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Mana required")


func create_autocasts() -> Array[Autocast]:
	var list: Array[Autocast] = []

	var autocast1: Autocast = Autocast.make()
	autocast1.title = "Cloudy Thunderstorm"
	autocast1.icon = "res://Resources/Icons/electricity/lightning_circle_white.tres"
	autocast1.description_short = "Summons [color=GOLD]Cloudy Thunderstorm[/color] which strikes random creeps in range, dealing spell damage.\n"
	autocast1.description = "Summons [color=GOLD]Cloudy Thunderstorm[/color] which strikes random creeps in 1000 range every 0.4 seconds with lightning. Each strike deals [color=GOLD][current mana x 0.5][/color] spell damage and costs mana based on the target's size and the damage dealt. The storm ends when this tower's mana falls below 1000, or no creep comes within range for 4 seconds.\n" \
	+ " \n" \
	+ "This ability will also activate automatically when this tower's mana reaches a set threshold, as determined by the [color=GOLD]Adjust Autocast Threshold[/color] ability. You can check current threshold in Tower Details.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.02 damage per current mana\n"
	autocast1.caster_art = ""
	autocast1.target_art = ""
	autocast1.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast1.num_buffs_before_idle = 0
	autocast1.cast_range = 1000
	autocast1.auto_range = 0
	autocast1.cooldown = 0.01
	autocast1.mana_cost = 1000
	autocast1.target_self = false
	autocast1.is_extended = false
	autocast1.buff_type = null
	autocast1.target_type = TargetType.new(TargetType.CREEPS)
	autocast1.handler = on_autocast_cloud_thunderstorm
	list.append(autocast1)

	var autocast2: Autocast = Autocast.make()
	autocast2.title = "Adjust Thunderstorm Threshold"
	autocast2.icon = "res://Resources/Icons/mechanical/compass.tres"
	autocast2.description_short = "Adjust the percentual mana required for [color=GOLD]Cloudy Thunderstorm[/color].\n"
	autocast2.description = "Use this ability to adjust the percentual mana required for [color=GOLD]Cloudy Thunderstorm[/color].\n" \
	+ " \n" \
	+ "You can check current threshold in Tower Details.\n"
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
	list.append(autocast2)

	return list


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Cloud of Absorption"
	aura.icon = "res://Resources/Icons/trinkets/trinket_01.tres"
	aura.description_short = "Creates a lightning ball if a creep in range is killed with more damage than needed. The lighting ball absorbs the redundant damage and transfers it to this temple as mana.\n"
	aura.description_full = "Creates a lightning ball if a creep in %d range is killed with more damage than needed. The lighting ball absorbs the redundant damage and transfers it to this temple. Every 1 damage absorbed grants 1 mana.\n" % AURA_RANGE \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.05 mana per absorbed damage\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 1
	aura.level_add = 1
	aura.power = 1
	aura.power_add = 1
	aura.aura_effect = aura_bt
	return [aura]


func on_autocast_cloud_thunderstorm(_event: Event):
	if !storm_is_enabled:
		enable_storm()


func on_autocast_adjust_threshold(_event: Event):
	threshold_for_cloudy_thunderstorm_autocast += 0.1
	if threshold_for_cloudy_thunderstorm_autocast > 1.0:
		threshold_for_cloudy_thunderstorm_autocast = 0.0

	var floating_text: String = Utils.format_percent(threshold_for_cloudy_thunderstorm_autocast, 0)
	tower.get_player().display_small_floating_text(floating_text, tower, Color8(155, 155, 255), 40.0)


func on_tower_details() -> MultiboardValues:
	var mana_required: String = Utils.format_percent(threshold_for_cloudy_thunderstorm_autocast, 0)
	multiboard.set_value(0, mana_required)

	return multiboard


func on_destruct():
	if storm_effect != 0:
		Effect.destroy_effect(storm_effect)


func on_unit_in_range(event: Event):
	var target: Unit = event.get_target()

	if !storm_is_enabled && !target.is_immune():
		var threshold_reached: bool = tower.get_mana_ratio() > threshold_for_cloudy_thunderstorm_autocast

		if threshold_reached:
			enable_storm()


func periodic(_event: Event):
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
			storm_bt.apply(tower, target, 1)
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
func storm_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var target: Creep = buff.get_buffed_unit()
#	Calculate how much damage is really dealt
	var dmg_taken: float = min(event.damage, target.get_health())
	var target_size: CreepSize.enm = target.get_size_including_challenge_sizes()
	var mana_loss: float = dmg_taken * 0.1 * storm_mana_reduction_values[target_size]

#	Remove mana from the tower according to the damage taken
#	and the size of the creep
	caster.subtract_mana(mana_loss, true)
	buff.remove_buff()


func enable_storm():
	if storm_is_enabled:
		return

	storm_is_enabled = true
	storm_effect = Effect.create_animated("CloudOfFog.mdl", Vector3(tower.get_x(), tower.get_y(), tower.get_z() + 30), 0.0)


# --- Aura Buff + Projectile Handling ---
# If a creep with the auras buff is killed, a projectile spawns
# Reaction of a natac_obsorption_AuraBuffType on Damage
func aura_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var caster: Unit = buff.get_caster()
	var damage: float = event.damage
	var life: float = target.get_health()

	var target_will_die: bool = damage > life
	var target_is_affected_by_storm: bool = target.get_buff_of_type(storm_bt) != null

	if target_will_die && !target_is_affected_by_storm:
		var mana_ball: Projectile = Projectile.create_from_unit_to_unit(missile_pt, caster, 0.0, 0.0, target, caster, true, false, false)
		var redundant_damage: float = damage - life
		mana_ball.user_real = redundant_damage


func missile_pt_on_hit(projectile: Projectile, target: Unit):
	if target == null || !Utils.unit_is_valid(target):
		return

	var max_mana: float = target.get_overall_mana()
	var current_mana: float = target.get_mana()
	var redundant_damage: float = projectile.user_real
	var granted_mana: float = redundant_damage * (1.0 + 0.05 * target.get_level())

	if granted_mana > 0:
		target.add_mana(granted_mana)

	var actual_granted_mana: float = min(max_mana - current_mana, granted_mana)
	var floating_text: String = "+%s" % str(int(actual_granted_mana))
	target.get_player().display_small_floating_text(floating_text, target, Color8(0, 0, 255), 40)

	var mana_is_full: bool = current_mana + granted_mana >= max_mana

	if !storm_is_enabled && mana_is_full:
		enable_storm()
