extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] fixed bug in original script
# where it had special values for challenge creep sizes but
# failed to use them because it used Creep.getSize()
# function which substitues challenge sizes into mass/boss.

# NOTE: [ORIGINAL_GAME_BUG] fixed bug in original script
# where pig speed was the same for all tower tiers.

# NOTE: changed Initiative stacks from ints to floats. This
# way, the total can be 16 instead of confusing 48.


class PigData:
	var dmg: float = 0
	var crit: float = 0
	var spell_crit: float = 0
	var splash: float = 0
	var target_is_air: bool = false


var boar_pt: ProjectileType
var air_boar_pt: ProjectileType
var projectile_to_pig_data_map: Dictionary = {}
var initiative_stack_count: float = 0

const creep_size_to_initiative_stack: Dictionary = {
	CreepSize.enm.MASS: 1,
	CreepSize.enm.CHALLENGE_MASS: 1.33,
	CreepSize.enm.NORMAL: 2,
	CreepSize.enm.CHAMPION: 3.33,
	CreepSize.enm.AIR: 3.33,
	CreepSize.enm.BOSS: 8.33,
	CreepSize.enm.CHALLENGE_BOSS: 8.33,
}
const HOME_RANGE_BONUS_FOR_BOSSES: float = 75
const HOME_RANGE_ADD: float = 2
const SPLASH_DMG_RATIO: float = 0.15
const SPLASH_DMG_RATIO_ADD: float = 0.004
const SPLASH_RADIUS: float = 375
const INITIATIVE_STACK_MAX: float = 16


func get_tier_stats() -> Dictionary:
	return {
		1: {initiative_range = 900, pig_count = 2, home_range = 275, pig_speed = 380, pig_speed_add = 2},
		2: {initiative_range = 900, pig_count = 3, home_range = 290, pig_speed = 390, pig_speed_add = 4},
		3: {initiative_range = 1400, pig_count = 3, home_range = 310, pig_speed = 400, pig_speed_add = 8},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, _stats.initiative_range, TargetType.new(TargetType.CREEPS))


func tower_init():
	tower.hide_attack_projectiles()

	boar_pt = ProjectileType.create_ranged("res://src/projectiles/projectile_visuals/flying_pork.tscn", 1500, _stats.pig_speed, self)
	boar_pt.disable_explode_on_expiration()
	boar_pt.enable_collision(boar_pt_on_collide, 0.0, TargetType.new(TargetType.CREEPS), false)
	boar_pt.enable_homing(boar_pt_on_hit, 20)
	boar_pt.enable_periodic(boar_pt_periodic, 1.0)
	boar_pt.set_event_on_cleanup(boar_pt_on_cleanup)

	air_boar_pt = ProjectileType.create_interpolate("res://src/projectiles/projectile_visuals/flying_pork.tscn", 880, self)
	air_boar_pt.disable_explode_on_expiration()
	air_boar_pt.set_event_on_interpolation_finished(air_boar_pt_on_hit)
	air_boar_pt.set_event_on_cleanup(air_boar_pt_on_cleanup)


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var target_pos: Vector3 = target.get_position_wc3()
	var target_size: CreepSize.enm = target.get_size()
	var target_is_air: bool = target_size == CreepSize.enm.AIR
	var pig_count: int = get_base_pig_count()

	do_rampage_of_pigs(target, target_pos, target_is_air, pig_count)


func on_kill(event: Event):
	var target: Unit = event.get_target()
	do_initiative_ability(target)


func on_damage(event: Event):
	event.damage = 0


func on_unit_in_range(event: Event):
	var target: Unit = event.get_target()
	do_initiative_ability(target)


# NOTE: deem_BoarHome() in original script
func boar_pt_on_collide(p: Projectile, target: Unit):
	if target.get_size() == CreepSize.enm.AIR:
		return

	if target == null:
		return

	p.set_collision_enabled(false)
	p.set_homing_target(target)
	p.set_acceleration(24)
	p.set_color(Color8(255, 95, 95, 255))
	p.disable_periodic()


func boar_pt_on_hit(p: Projectile, target: Unit):
	generic_boar_pt_on_hit(p, target)


# NOTE: deem_BoarPeriodic() in original script
func boar_pt_periodic(p: Projectile):
	var new_direction: float = p.get_direction() + Globals.synced_rng.randf_range(-1, 1) * 12
	p.set_direction(new_direction)


func boar_pt_on_cleanup(p: Projectile):
	generic_boar_on_cleanup(p)


func air_boar_pt_on_hit(p: Projectile, target: Unit):
	generic_boar_pt_on_hit(p, target)


func air_boar_pt_on_cleanup(p: Projectile):
	generic_boar_on_cleanup(p)


# NOTE: deem_BoarClean() in original script
func generic_boar_on_cleanup(p: Projectile):
	projectile_to_pig_data_map.erase(p)


func do_initiative_ability(target: Unit):
#	NOTE: important to use
#	get_size_including_challenge_sizes() here instead of
#	get_size() to get challenge sizes. Challenge sizes have
#	special values for initiative stacks.
	var target_size: CreepSize.enm = target.get_size_including_challenge_sizes()
	var initiative_stack: float = creep_size_to_initiative_stack[target_size]
	initiative_stack_count += initiative_stack

	while initiative_stack_count > INITIATIVE_STACK_MAX:
		initiative_stack_count -= INITIATIVE_STACK_MAX

		CombatLog.log_ability(tower, target, "Rampage of Pigs")

		var target_pos: Vector3 = target.get_position_wc3()
		var target_is_air: bool = target_size == CreepSize.enm.AIR
		var pig_count: int = get_base_pig_count()
		do_rampage_of_pigs(target, target_pos, target_is_air, pig_count)


# NOTE: need to pass target_pos_3d and target_is_air because
# the tower shoots pigs with a delay and needs to keep
# shooting at target's position even after it dies.
# NOTE: PigNuggetOnAttack() + pignuggetlauncher() in
# original script
func do_rampage_of_pigs(target: Creep, target_pos_3d: Vector3, target_is_air, remaining_pig_count: int):
	var target_pos: Vector2 = Vector2(target_pos_3d.x, target_pos_3d.y)
	
	var level: int = tower.get_level()

	var pig_speed: float = _stats.pig_speed + _stats.pig_speed_add * level

	var tower_pos_3d: Vector3 = tower.get_position_wc3()
	var tower_pos: Vector2 = tower.get_position_wc3_2d()
	var vector_to_target: Vector2 = target_pos - tower_pos
	var pig_direction: float = rad_to_deg(vector_to_target.angle())

	var projectile: Projectile
	if target_is_air:
		if Utils.unit_is_valid(target):
			var start_pos: Vector3 = Vector3(
				tower.get_x() + Globals.synced_rng.randi_range(-25, 25),
				tower.get_y() + Globals.synced_rng.randi_range(-25, 25),
				tower.get_z())
			var z_arc: float = Globals.synced_rng.randf_range(0, 0.2)
			projectile = Projectile.create_linear_interpolation_from_point_to_unit(air_boar_pt, tower, 0, 0, start_pos, target, z_arc, true)
		else:
			var start_pos: Vector3 = tower_pos_3d + Vector3(
				Globals.synced_rng.randi_range(-25, 25),
				Globals.synced_rng.randi_range(-25, 25),
				0
				)
			var end_pos: Vector3 = target_pos_3d + Vector3(
				Globals.synced_rng.randi_range(-50, 50),
				Globals.synced_rng.randi_range(-50, 50),
				Globals.synced_rng.randi_range(-35, 35),
				)
			var z_arc: float = Globals.synced_rng.randf_range(0, 0.3)
			projectile = Projectile.create_linear_interpolation_from_point_to_point(air_boar_pt, tower, 0, 0, start_pos, end_pos, z_arc)

		projectile.set_color(Color8(255, 105, 105, 255))
	else:
		var start_pos: Vector3 = Vector3(
			tower.get_x() + Globals.synced_rng.randi_range(-25, 25),
			tower.get_y() + Globals.synced_rng.randi_range(-25, 25),
			tower.get_z() + 5.0)
		var facing: float = pig_direction + 16 * Globals.synced_rng.randf_range(-1, 1)
		projectile = Projectile.create(boar_pt, tower, 0, 0, start_pos, facing)
		
		var home_range: float = _stats.home_range
		if Utils.unit_is_valid(target):
			var target_size: CreepSize.enm = target.get_size()
			var target_is_boss: bool = target_size == CreepSize.enm.BOSS
			if target_is_boss:
				home_range += HOME_RANGE_BONUS_FOR_BOSSES

		projectile.set_collision_parameters(home_range, TargetType.new(TargetType.CREEPS))

		projectile.set_speed(pig_speed)

	var pig_data: PigData = PigData.new()
	pig_data.dmg = tower.get_current_attack_damage_with_bonus()
	pig_data.crit = tower.calc_attack_multicrit_no_bonus()
	pig_data.spell_crit = tower.calc_spell_crit_no_bonus()
	pig_data.splash = SPLASH_DMG_RATIO + SPLASH_DMG_RATIO_ADD * level
	pig_data.target_is_air = target_is_air

	projectile_to_pig_data_map[projectile] = pig_data

	remaining_pig_count -= 1

	if remaining_pig_count > 0:
		await Utils.create_manual_timer(0.25, self).timeout
		
		var update_target_pos_3d: Vector3
		if Utils.unit_is_valid(target):
			update_target_pos_3d = target.get_position_wc3()
		else:
			update_target_pos_3d = target_pos_3d
			
#		NOTE: need to convert to null to avoid errors about
#		passing previously freed reference
		var updated_target: Unit
		if Utils.unit_is_valid(target):
			updated_target = target
		else:
			updated_target = null

		do_rampage_of_pigs(updated_target, update_target_pos_3d, target_is_air, remaining_pig_count)


# NOTE: deem_BoarHit() in original script
func generic_boar_pt_on_hit(p: Projectile, target: Unit):
	var pig_data: PigData = projectile_to_pig_data_map.get(p, null)

	if pig_data == null:
		push_error("pig_data is somehow null.")

		return

	var target_is_air: bool = pig_data.target_is_air

	if target != null || target_is_air:
		if target != null:
			tower.do_attack_damage(target, pig_data.dmg, pig_data.crit)
			var effect: int = Effect.create_simple_at_unit_attached("res://src/effects/doom_death.tscn", target, Unit.BodyPart.ORIGIN)
			Effect.set_z_index(effect, -1)

		var pig_pos: Vector2 = p.get_position_wc3_2d()
		var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), pig_pos, SPLASH_RADIUS)

		var hit_count: int = 0
		while true:
			var next: Unit = it.next()

			if next == null:
				break

			if !next.is_immune():
				hit_count += 1

		if hit_count > 0:
#			Split splash damage to target count
			var splash_damage: float = pig_data.dmg * pig_data.splash / hit_count

			tower.do_spell_damage_aoe(pig_pos, SPLASH_RADIUS, splash_damage, pig_data.spell_crit, 0)
	else:
		p.avert_destruction()
		p.set_collision_enabled(true)
		p.set_acceleration(0)
		p.set_speed(400)
		p.set_color(Color.WHITE)
		p.enable_periodic(1.0)


func get_base_pig_count() -> int:
	var pig_count: int = _stats.pig_count

	var level: int = tower.get_level()
	if level >= 5:
		pig_count += 1
	if level >= 15:
		pig_count += 1

	return pig_count
