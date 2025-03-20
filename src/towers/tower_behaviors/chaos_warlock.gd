extends TowerBehavior

# NOTE: [ORIGINAL_GAME_DEVIATION] Renamed
# "Eredar Warlock"=>"Chaos Warlock"


# NOTE: [ORIGINAL_GAME_DEVIATION] changed autocast.buff_type
# (null->siphon_bt). This fixes an issue where autocast
# would rebuff the unit which is already buffed. Now, the
# autocast will buff only units which don't already have the
# buff.


var stun_bt: BuffType
var siphon_bt: BuffType
var aura_bt: BuffType
var wave_shadowbolt_pt: ProjectileType
var attack_shadowbolt_pt: ProjectileType

var last_autocast_triggered_bolt_wave: bool = false

const AURA_RANGE: int = 750


func get_tier_stats() -> Dictionary:
	return {
		1: {autocast_cooldown = 2.5, bolt_count = 10, bolt_damage = 1050, bolt_damage_add = 21},
		2: {autocast_cooldown = 1.5, bolt_count = 12, bolt_damage = 1700, bolt_damage_add = 34},
	}


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)

	siphon_bt = BuffType.new("siphon_bt", 5, 0, true, self)
	siphon_bt.set_buff_icon("res://resources/icons/generic_icons/omega.tres")
	siphon_bt.add_event_on_attack(siphon_bt_on_attack)
	siphon_bt.set_buff_tooltip("Siphon Essence\nStuns tower on attack.")

	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/alien_skull.tres")
	aura_bt.add_periodic_event(aura_bt_periodic, 1.0)
	aura_bt.set_buff_tooltip("Slow Decay Aura\nKills creep instantly if it reaches low health.")

#	NOTE: this tower uses two separate projectile types.
#	1. The first one is launched from the tower in all
#	   directions - not targeted at creeps.
#  	2. When the first projectiles expire, they transform
#  	   into homing projectiles, which are now targeted at
#  	   creeps.
	wave_shadowbolt_pt = ProjectileType.create_ranged("path_to_projectile_sprite", 300, 600, self)
	wave_shadowbolt_pt.set_event_on_expiration(wave_shadowbolt_pt_on_expire)

	attack_shadowbolt_pt = ProjectileType.create("path_to_projectile_sprite", 4, 1000, self)
	attack_shadowbolt_pt.enable_homing(attack_shadowbolt_pt_on_hit, 0)


func on_autocast(event: Event):
	var target: Tower = event.get_target()
	siphon_bt.apply(tower, target, 1)
	roll_for_shadow_wave()


func roll_for_shadow_wave():
	var wave_chance: float
	if last_autocast_triggered_bolt_wave:
		wave_chance = 0.20
	else:
		wave_chance = 0.40

	if !tower.calc_chance(wave_chance):
		last_autocast_triggered_bolt_wave = false

		return
	else:
		last_autocast_triggered_bolt_wave = true

	CombatLog.log_ability(tower, null, "Shadowbolt Wave")

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1000)

	if it.count() == 0:
		return

	var angle: float = 0.0
	var tower_pos: Vector2 = tower.get_position_wc3_2d()

#	Create projectiles which radiate around the tower
	for i in range(0, _stats.bolt_count):
		angle += 360 / _stats.bolt_count
		var offset: Vector2 = Vector2(300, 0).rotated(deg_to_rad(angle))
		var target_pos_2d: Vector2 = tower_pos + offset
		var target_pos: Vector3 = Vector3(target_pos_2d.x, target_pos_2d.y, tower.get_z())
		Projectile.create_from_unit_to_point(wave_shadowbolt_pt, tower, 1.0, 1.0, tower, target_pos, false, false)	


func siphon_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var warlock: Tower = buff.get_caster()
	var attacker: Tower = buff.get_buffed_unit()
	var target: Unit = event.get_target()
	var dmg: float = 3 * attacker.get_current_attack_damage_with_bonus() / attacker.get_current_attack_speed()
	var stun_duration: float = 2.5 - 0.02 * warlock.get_level()

	stun_bt.apply_only_timed(warlock, attacker, stun_duration)

# 	NOTE: need to separately call order_stop() to stop
# 	current attack of buffed tower. Note that applying
# 	stun_bt will not stop an attack which is already in
# 	progress.
	attacker.order_stop()

#	NOTE: calc_spell_crit_no_bonus() is used in original
#	script even though this is do_attack_damage(). Maybe on
#	purpose?
	warlock.do_attack_damage(target, dmg, warlock.calc_spell_crit_no_bonus())

	Effect.create_simple_at_unit("res://src/effects/impale_hit_target.tscn", attacker, Unit.BodyPart.ORIGIN)

	var floating_text: String = Utils.format_float(dmg, 0)
	warlock.get_player().display_floating_text_x(floating_text, target, Color8(255, 0, 150, 255), 0.05, 0.0, 2.0)

	Effect.create_simple_at_unit("res://src/effects/impale_hit_target.tscn", target, Unit.BodyPart.ORIGIN)


func aura_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	var target: Unit = buff.get_buffed_unit()
	var is_less_than_boss: bool = target.get_size() < CreepSize.enm.BOSS
	var low_health_threshold: float = 0.055 + 0.0006 * caster.get_level()
	var is_low_health: bool = target.get_health_ratio() <= low_health_threshold

	if is_low_health && is_less_than_boss:
		caster.kill_instantly(target)
		Effect.create_simple_at_unit("res://src/effects/death_coil.tscn", target)


func wave_shadowbolt_pt_on_expire(projectile: Projectile):
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1000)

	if it.count() != 0:
		var random_creep: Unit = it.next_random()
		var projectile_pos: Vector3 = projectile.get_position_wc3()
		Projectile.create_from_point_to_unit(attack_shadowbolt_pt, tower, 1.0, 1.0, projectile_pos, random_creep, true, false, false)


func attack_shadowbolt_pt_on_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	var damage: float = _stats.bolt_damage + _stats.bolt_damage_add * tower.get_level()
	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())
