extends TowerBehavior


# NOTE: Changes compared to original script:
# - Removed usage of p.userInt
# - Inverted order of looping through cones, start looping
#   from closest and increase distance.
# - Changed position used when checking if copter should
#   turn to tower. Original script (incorrectly?) used the
#   copter position before any abilities were performed.
#   This means that if copter teleported, then it used
#   completely innaccurate position. Changed to use position
#   of copter after abilities.
# - Changed center of tesla ability to be equal to position
#   of picked main target instead of the position on the
#   line in front of helicopter closest to main target. This
#   is just because it works better in code like this. Not a
#   big difference in final behavior.
# - Didn't implement fading for teleport ability. Maybe will
#   later.


enum CopterAbility {
	NONE,
	NAPALM,
	TESLA,
	GHOST,
}

class Copter:
	var projectile: Projectile = null
	var active_ability: CopterAbility = CopterAbility.NONE
	var ghost_ability_timer: int = 0


var copter_slow_bt: BuffType
var copter_armor_bt: BuffType
var copter_napalm_bt: BuffType
var copter_pt: ProjectileType

var copter_map: Dictionary = {}
var projectile_to_copter_map: Dictionary = {}

const MISSILE_RADIUS: float = 140
const TESLA_RADIUS: float = 140 * 1.5
const MISSILE_SPACING: float = 250
const MISSILE_COUNT_MAX: int = 3
const THRESHOLD_TO_START_TURNING_TO_TOWER: float = 550
const THRESHOLD_TO_SPEED_UP: float = 480
# NOTE: picked 300 so that copter goes straight for 1.2
# seconds when it starts shooting:
# -- (480 - 300) / 30 * 0.2 = 1.2
const COPTER_SPEED_WHEN_START_SHOOTING: float = 300

const TURN_TO_TARGET_SPEED: float = 6
const TURN_TO_TARGET_MARGIN: float = 4
const TURN_TO_TOWER_SPEED: float = 6
const TURN_TO_TOWER_MARGIN: float = 25
const GHOST_ABILITY_TIMER_MAX: int = 20


func get_ability_info_list() -> Array[AbilityInfo]:
	var physical_string: String = AttackType.convert_to_colored_string(AttackType.enm.PHYSICAL)
	var elemental_string: String = AttackType.convert_to_colored_string(AttackType.enm.ELEMENTAL)
	var energy_string: String = AttackType.convert_to_colored_string(AttackType.enm.ENERGY)

	var list: Array[AbilityInfo] = []
	
	var special_training: AbilityInfo = AbilityInfo.new()
	special_training.name = "Special Training"
	special_training.icon = "res://resources/icons/books/book_06.tres"
	special_training.description_short = "On higher levels, copters gain special abilities.\n"
	special_training.description_full = "On higher levels the copters specialize.\n" \
	+ "On level 7: Copter #1 has its damage type changed to %s, each rocket's AoE is increased by 25%% and the attacks gain a napalm modifier. Napalm causes a 20%% slow and 50%% of the tower's attack damage as %s damage per second for 5 seconds.\n" % [elemental_string, elemental_string] \
	+ " \n" \
	+ "On level 15: Copter #2 will change its machine-gun-missiles to a long ranged tesla coil, changing the damage type to %s and increasing attack range to 210. Furthermore its armor reduction base effect is increased to 50%%, but the slow is decreased to 10%%.\n" % [energy_string] \
	+ " \n" \
	+ "On level 25: Copter #3 will become a legendary Ghost Warrior. Ghost Warriors have an on-board teleportation device, allowing them to teleport behind targets every 5 seconds. Shooting delays the charging of the teleportation device.\n" \
	+ ""
	list.append(special_training)

	var helicopter_zone: AbilityInfo = AbilityInfo.new()
	helicopter_zone.name = "Helicopter Zone"
	helicopter_zone.icon = "res://resources/icons/armor/vest_02.tres"
	helicopter_zone.description_short = "3 helicopters circle around the tower trying to stay within 1000 range of it. The helicopters attack creeps in front of them, dealing the tower's attack damage. Helicopters also reduce movement speed and armor of hit creeps. These helicopters are not affected by attack speed.\n"
	helicopter_zone.description_full = "3 helicopters circle around the tower trying to stay within 1000 range of it. If there are creeps in front of a helicopter, it will attack them dealing the tower's attack damage as %s damage.\n"  % [physical_string] \
	+ " \n" \
	+ "Helicopters attack every 0.25 seconds with a barrage of 3 missiles spaced 250 range apart and exploding in 140 AoE. Hit creeps are slowed by 50% and their armor is reduced by 30% for 0.8 seconds. Not affected by attack speed.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% armor reduction\n" \
	+ ""
	list.append(helicopter_zone)

	return list


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	autocast.title = "Targeted Run"
	autocast.icon = "res://resources/icons/rings/ring_06.tres"
	autocast.description_short = "Copter #1 will teleport behind the target after a delay.\n"
	autocast.description = "Copter #1 will teleport behind the target after a delay of 1 second.\n"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 1000
	autocast.auto_range = 1000
	autocast.cooldown = 15
	autocast.mana_cost = 0
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast

	return [autocast]


func load_triggers(triggers: BuffType):
	triggers.add_event_on_level_up(on_level_up)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	tower.hide_attack_projectiles()
	
	copter_slow_bt = BuffType.new("copter_slow_bt", 0.8, 0, false, self)
	var copter_slow_bt_mod: Modifier = Modifier.new()
	copter_slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.1, -0.01)
	copter_slow_bt.set_buff_modifier(copter_slow_bt_mod)
	copter_slow_bt.set_buff_icon("res://resources/icons/generic_icons/cog.tres")
	copter_slow_bt.set_buff_tooltip("Copter Slow\nMovement speed is reduced.")

	copter_armor_bt = BuffType.new("copter_armor_bt", 0.8, 0, false, self)
	var copter_armor_bt_mod: Modifier = Modifier.new()
	copter_armor_bt_mod.add_modification(Modification.Type.MOD_ARMOR_PERC, -0.3, -0.004)
	copter_armor_bt.set_buff_modifier(copter_armor_bt_mod)
	copter_armor_bt.set_buff_icon("res://resources/icons/generic_icons/azul_flake.tres")
	copter_armor_bt.set_buff_tooltip("Copter armor\nArmor is reduced.")

	copter_napalm_bt = BuffType.new("copter_napalm_bt", 5, 0, false, self)
	var copter_napalm_bt_mod: Modifier = Modifier.new()
	copter_napalm_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.2, 0.0)
	copter_napalm_bt.set_buff_modifier(copter_napalm_bt_mod)
	copter_napalm_bt.set_buff_icon("res://resources/icons/generic_icons/mine_explosion.tres")
	copter_napalm_bt.set_buff_tooltip("Copter Napalm\nDeals damage over time.")
	copter_napalm_bt.add_periodic_event(copter_napalm_bt_periodic, 1.0)
	copter_napalm_bt.add_event_on_create(copter_napalm_bt_on_create)

	copter_pt = ProjectileType.create("Gyrocopter.mdl", 999999, 10, self)
	copter_pt.enable_periodic(copter_pt_periodic, 0.25)


func on_create(_preceding: Tower):
	var tower_pos: Vector2 = tower.get_position_wc3_2d()

	for i in range(0, 3):
		var facing: float = 120 * i
		var p: Projectile = Projectile.create_from_unit(copter_pt, tower, tower, facing, 0, 0)
		var copter_offset: Vector2 = Vector2(
			(i - 1) * (-80),
			(i - 1) * (i - 1) * (-80) - 40
			)
		var copter_pos: Vector3 = Vector3(
			tower_pos.x + copter_offset.x,
			tower_pos.y + copter_offset.y,
			225)
		p.set_position_wc3(copter_pos)

		p.user_int2 = 0
		p.user_int3 = 0

		var copter: Copter = Copter.new()
		copter.projectile = p
		copter.active_ability = CopterAbility.NONE
		copter_map[i] = copter
		projectile_to_copter_map[p] = copter

	level_up_copters()


func on_destruct():
	for copter in copter_map.keys():
		var projectile: Projectile = copter.projectile
		projectile.remove_from_game()


func on_level_up(_event: Event):
	level_up_copters()


func on_damage(event: Event):
	event.damage = 0


# NOTE: onAutocast() + UPANDRUN() in original script
func on_autocast(event: Event):
	var target: Unit = event.get_target()

	await Utils.create_timer(1.0, self).timeout

	if !Utils.unit_is_valid(tower) || !Utils.unit_is_valid(target):
		return

	var copter_1: Copter = copter_map[0]
	var projectile: Projectile = copter_1.projectile
	projectile.set_speed(COPTER_SPEED_WHEN_START_SHOOTING)
	move_projectile_behind_unit(projectile, target, 0, 100)


# NOTE: Periodic_CopterNapalm() in original script
func copter_napalm_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var napalm_damage: float = buff.user_real

	tower.do_custom_attack_damage(buffed_unit, napalm_damage, tower.calc_attack_crit_no_bonus(), AttackType.enm.ELEMENTAL)


# When applying Napalm, user_real is checked if new damage
# is greater before setting it, so we need to initialize it
# here.
# NOTE: napalm_onCreate() in original script
func copter_napalm_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var napalm_damage_initial: float = 0
	buff.user_real = napalm_damage_initial


# The main function which controls copters, adjusts
# trajectory, and performs copter abilities.
# NOTE: Copter_Periodic() in original script
func copter_pt_periodic(p: Projectile):
	var copter: Copter = projectile_to_copter_map[p]

	if copter.active_ability == CopterAbility.GHOST:
		copter_ability_ghost(copter)

	var target: Unit = copter_find_target_in_front(copter)
	
	if target != null:
		copter_turn(p, target, TURN_TO_TARGET_SPEED, TURN_TO_TARGET_MARGIN)

		if copter.active_ability == CopterAbility.TESLA:
			copter_ability_tesla_coil(copter, target)
		else:
			copter_ability_shoot_in_front(copter)

	var copter_should_speed_up: bool = p.get_speed() < THRESHOLD_TO_SPEED_UP
	
	var copter_pos: Vector2 = p.get_position_wc3_2d()
	var tower_pos: Vector2 = tower.get_position_wc3_2d()
	var distance_to_tower_squared: float = copter_pos.distance_squared_to(tower_pos)
	var copter_should_turn_to_tower: bool = distance_to_tower_squared > THRESHOLD_TO_START_TURNING_TO_TOWER ** 2

	if copter_should_speed_up:
		var new_speed: float = p.get_speed() + 30
		p.set_speed(new_speed)
	elif copter_should_turn_to_tower:
		copter_turn(p, tower, TURN_TO_TOWER_SPEED, TURN_TO_TOWER_MARGIN)


func copter_ability_ghost(copter: Copter):
	var projectile: Projectile = copter.projectile
	var copter_pos: Vector2 = projectile.get_position_wc3_2d()
	var can_use_ghost_ability: bool = copter.ghost_ability_timer == GHOST_ABILITY_TIMER_MAX

	if can_use_ghost_ability:
		var max_shoot_range: float = MISSILE_SPACING * MISSILE_COUNT_MAX
		var ghost_teleport_range: float = 3 * max_shoot_range
		var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), copter_pos, ghost_teleport_range)

		var target: Unit = it.next()

		if target != null:
			copter.ghost_ability_timer = 21

			var random_direction_offset: float = Globals.synced_rng.randf_range(-15, 15)
			move_projectile_behind_unit(projectile, target, random_direction_offset, 0)
	else:
		copter.ghost_ability_timer += 1

#		0-15 fade out, 15 wait for target, 15-20 fade in
		var new_color: Color
		if copter.ghost_ability_timer > 20:
			new_color = Color8(80, 80, 80, 63 + (copter.ghost_ability_timer - 21) * 48)
		else:
			new_color = Color8(80, 80, 80, roundi(255 - copter.ghost_ability_timer * 9.6))
		projectile.set_color(new_color)

#		If faded in, start fading out again
		if copter.ghost_ability_timer == 25:
			copter.ghost_ability_timer = 0


# Makes the copter deal AoE damage in a line in front of it
func copter_ability_shoot_in_front(copter: Copter):
	var p: Projectile = copter.projectile
	var copter_pos: Vector2 = p.get_position_wc3_2d()
	p.set_speed(COPTER_SPEED_WHEN_START_SHOOTING)
	
	var copter_direction: float = p.get_direction()
	var vector_between_missiles: Vector2 = Vector2(MISSILE_SPACING, 0).rotated(deg_to_rad(copter_direction))

	var missile_count: int = 0

	while true:
		if missile_count >= MISSILE_COUNT_MAX:
			break

		var target_pos: Vector2 = copter_pos + vector_between_missiles * missile_count

		copter_ability_shoot_one_missile(copter, target_pos)

		missile_count += 1


# Makes the copter deal AoE damage at one position
# NOTE: CopterShotHit() in original script
func copter_ability_shoot_one_missile(copter: Copter, target_pos: Vector2):
	var napalm_is_active: bool = copter.active_ability == CopterAbility.NAPALM

	var missile_radius: float
	if napalm_is_active:
		missile_radius = MISSILE_RADIUS * 1.25
	else:
		missile_radius = MISSILE_RADIUS

	var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), target_pos, missile_radius)

	var effect: int = Effect.add_special_effect("res://src/effects/explosion.tscn", target_pos)
	Effect.set_scale(effect, 1.5)
	Effect.set_lifetime(effect, 0.5)

	var attack_damage: float = tower.get_current_attack_damage_with_bonus()

	while true:
		var target: Unit = it.next()

		if target == null:
			break

		var health_before: float = target.get_health()

		if napalm_is_active:
			tower.do_custom_attack_damage(target, attack_damage, tower.calc_attack_multicrit_no_bonus(), AttackType.enm.ELEMENTAL)

			var health_decreased: bool = target.get_health() < health_before
			if health_decreased:
				var napalm_buff: Buff = copter_napalm_bt.apply(tower, target, 0)

				var current_napalm_damage: float = napalm_buff.user_real
				var new_napalm_damage: float = 0.5 * attack_damage
				var new_napalm_damage_is_upgrade: bool = new_napalm_damage > current_napalm_damage
				if new_napalm_damage_is_upgrade:
					napalm_buff.user_real = new_napalm_damage

				copter_slow_bt.apply(tower, target, 40)
				copter_armor_bt.apply(tower, target, tower.get_level())
		else:
			tower.do_custom_attack_damage(target, attack_damage, tower.calc_attack_multicrit_no_bonus(), AttackType.enm.PHYSICAL)

			var health_decreased: bool = target.get_health() < health_before
			if health_decreased:
				copter_slow_bt.apply(tower, target, 40)
				copter_armor_bt.apply(tower, target, tower.get_level())


func copter_ability_tesla_coil(copter: Copter, main_target: Unit):
	var tesla_center: Vector2 = main_target.get_position_wc3_2d()
	var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), tesla_center, TESLA_RADIUS)
	
	var damage: float = tower.get_current_attack_damage_with_bonus()

	while true:
		var target: Unit = it.next()

		if target == null:
			break

		var projectile: Projectile = copter.projectile
		var copter_pos: Vector3 = projectile.get_position_wc3()
		var lightning: InterpolatedSprite = InterpolatedSprite.create_from_point_to_unit(InterpolatedSprite.LIGHTNING, copter_pos, target)
		lightning.set_lifetime(0.12)

		var health_before: float = target.get_health()

		tower.do_custom_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus(), AttackType.enm.ENERGY)

		var health_decreased: bool = target.get_health() < health_before

		if health_decreased:
			copter_armor_bt.apply(tower, target, tower.get_level() + 50)
			copter_slow_bt.apply(tower, target, 0)


# Find the nearest target in front of the copter
func copter_find_target_in_front(copter: Copter) -> Unit:
	var projectile: Projectile = copter.projectile
	var missile_count_max: int = MISSILE_COUNT_MAX
	var missile_radius: float = MISSILE_RADIUS
	if copter.active_ability == CopterAbility.TESLA:
		missile_count_max = 8
		missile_radius *= 1.5
	var copter_pos: Vector2 = projectile.get_position_wc3_2d()
	var copter_direction: float = projectile.get_direction()
	var spacing_vector: Vector2 = Vector2(MISSILE_SPACING, 0).rotated(deg_to_rad(copter_direction))
	var missile_count: int = 0
	
	while true:
		if missile_count >= missile_count_max:
			break

		var missile_pos: Vector2 = copter_pos + spacing_vector * missile_count
		var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), missile_pos, missile_radius)

		var target: Unit = it.next()

		if target != null:
			return target
		
		missile_count += 1
		
	return null


# Moves copter behind unit and also aligns the direction of
# the copter with the unit so that copter follows the
# target.
# NOTE: deem_fade() in original script. Also a portion of
# Copter_Periodic()
func move_projectile_behind_unit(projectile: Projectile, target: Unit, direction_offset: float, distance_offset: float):
	var new_direction: float = target.get_unit_facing()
	new_direction += direction_offset
	projectile.set_direction(new_direction)

	var max_shoot_range: float = MISSILE_SPACING * MISSILE_COUNT_MAX + distance_offset
	var target_pos: Vector2 = target.get_position_wc3_2d()
	var pos_behind_target: Vector2 = target_pos + Vector2(max_shoot_range, 0).rotated(deg_to_rad(new_direction + 180))
	projectile.set_position_wc3_2d(pos_behind_target)


# NOTE: deem_anglestuff() in original script
func copter_turn(p: Projectile, target: Unit, turn: float, angle_margin: float):
	var target_pos: Vector2 = target.get_position_wc3_2d()
	var diff_vector: Vector2 = target_pos - p.get_position_wc3_2d()
	var angle: float = rad_to_deg(diff_vector.angle())
	var angle_diff: float = angle - p.get_direction()

#	Normalize angle
	if angle_diff > 180:
		angle_diff -= 360
	elif angle_diff < -180:
		angle_diff += 360

	var new_direction: float
	if angle_diff > angle_margin:
		new_direction = p.get_direction() + turn
	elif angle_diff < -angle_margin:
		new_direction = p.get_direction() - turn
	else:
		new_direction = p.get_direction()

	p.set_direction(new_direction)


# NOTE: LevelUpCopters() in original script
func level_up_copters():
	var level: int = tower.get_level()
	var copter_1: Copter = copter_map[0]
	var copter_2: Copter = copter_map[1]
	var copter_3: Copter = copter_map[2]

	if level >= 7:
		copter_1.active_ability = CopterAbility.NAPALM
		copter_1.projectile.set_color(Color8(255, 120, 120))
	else:
		copter_1.active_ability = CopterAbility.NONE
		copter_1.projectile.set_color(Color8(255, 255, 255))

	if level >= 15:
		copter_2.active_ability = CopterAbility.TESLA
		copter_2.projectile.set_color(Color8(120, 120, 255))
	else:
		copter_2.active_ability = CopterAbility.NONE
		copter_2.projectile.set_color(Color8(255, 255, 255))

	if level >= 25:
		copter_3.active_ability = CopterAbility.GHOST
		copter_3.projectile.set_color(Color8(80, 80, 80))
		copter_3.ghost_ability_timer = 0
	else:
		copter_3.active_ability = CopterAbility.NONE
		copter_3.projectile.set_color(Color8(255, 255, 255))
		copter_3.ghost_ability_timer = 0
