extends TowerBehavior


# NOTE: for some reason, youtd website shows the "Glaivesaw"
# ability as "on_spell_cast" handler. It should be an
# autocast. Guessed the parameters for the autocast and
# implemented it.

# NOTE: original script has a bug where movement speed does
# not affect damage dealt by dot even though the ability
# description says that movement speed does affect damage.
# Preserved this bug.

# NOTE: every time this tower deals damage, it will show up
# as 0 damage in combat log and then non-zero damage from
# Lacerate. It looks weird but works as intended.


class Glaivesaw:
	var position: Vector2
	var effect_id: int


const GLAIVESAW_MAX: int = 3
var lacerate_bt: BuffType
var storm_pt: ProjectileType
var bounder_pt: ProjectileType
var glaivesaw_list: Array[Glaivesaw] = []


func get_ability_info_list() -> Array[AbilityInfo]:
	var physical_string: String = AttackType.convert_to_colored_string(AttackType.enm.PHYSICAL)
	var decay_string: String = AttackType.convert_to_colored_string(AttackType.enm.DECAY)

	var list: Array[AbilityInfo] = []
	
	var lacerate: AbilityInfo = AbilityInfo.new()
	lacerate.name = "Lacerate"
	lacerate.icon = "res://resources/icons/daggers/dagger_07.tres"
	lacerate.description_short = "This tower's attacks and abilities deal [color=GOLD]Lacerate[/color] damage. [color=GOLD]Lacerate[/color] splits normal damage into %s and %s damage over time.\n" % [physical_string, decay_string]
	lacerate.description_full = "This tower's attacks and abilities deal [color=GOLD]Lacerate[/color] damage. 50%% of [color=GOLD]Lacerate[/color] damage is dealt immediately as %s damage. 100%% of the remaining damage is dealt as %s damage over 5 seconds. If this effect is reapplied, any remaining damage will be added to the new duration. Damage over time is based on the target's movement speed, with faster movement increasing the damage dealt.\n" % [physical_string, decay_string] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% damage over time\n"
	list.append(lacerate)

	var glaive_storm: AbilityInfo = AbilityInfo.new()
	glaive_storm.name = "Glaive Storm"
	glaive_storm.icon = "res://resources/icons/daggers/dagger_02.tres"
	glaive_storm.description_short = "Whenever this tower hits a creep, it has a chance to throw an additional bouncing glaive at the target.\n"
	glaive_storm.description_full = "Whenever this tower hits a creep, it has a 5% chance to throw an additional bouncing glaive at the target, dealing 50% of attack damage as [color=GOLD]Lacerate[/color] damage before returning to the tower. When the glaive returns, it bounces to a new random target within attack range. Maximum of 20 hits.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.2% chance\n" \
	+ "+2% damage\n"
	list.append(glaive_storm)

	var bounder: AbilityInfo = AbilityInfo.new()
	bounder.name = "Bounder"
	bounder.icon = "res://resources/icons/daggers/dagger_04.tres"
	bounder.description_short = "Attacks have a chance to throw a glaive at one of the [color=GOLD]Glaivesaws[/color].\n"
	bounder.description_full = "Attacks have a 15% chance to throw a glaive towards one of the [color=GOLD]Glaivesaws[/color]. The glaive will bounce to another [color=GOLD]Glaivesaw[/color], dealing 250% of attack damage as [color=GOLD]Lacerate[/color] damage to enemies it passes through.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% chance\n" \
	+ "+6% damage\n"
	list.append(bounder)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 1.0)


func load_specials(_modifier: Modifier):
	tower.set_attack_style_bounce(2, 0.0)


func tower_init():
	lacerate_bt = BuffType.new("lacerate_bt", 5, 0, false, self)
	lacerate_bt.set_buff_icon("res://resources/icons/generic_icons/triple_scratches.tres")
	lacerate_bt.add_periodic_event(lacerate_bt_periodic, 1.0)
	lacerate_bt.set_buff_tooltip("Lacerate\nDeals damage over time.")

	storm_pt = ProjectileType.create_interpolate("SentinelMissile.mdl", 900, self)
	storm_pt.set_event_on_interpolation_finished(storm_pt_on_finished)

	bounder_pt = ProjectileType.create_interpolate("GlaiveMissile.mdl", 2000, self)
	bounder_pt.enable_collision(bounder_pt_on_collision, 100, TargetType.new(TargetType.CREEPS), false)
	bounder_pt.set_event_on_interpolation_finished(bounder_pt_on_finished)


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()
	
	autocast.title = "Glaivesaw"
	autocast.icon = "res://resources/icons/clubs/club_02.tres"
	autocast.description_short = "Create a [color=GOLD]Glaivesaw[/color] at the target location.\n"
	autocast.description = "Create a [color=GOLD]Glaivesaw[/color] at the target location. [color=GOLD]Glaivesaws[/color] deal 50% of attack damage as [color=GOLD]Lacerate[/color] damage per second to enemies within 150 range. Limited to 3 [color=GOLD]Glaivesaws[/color].\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% damage\n"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_NOAC_POINT
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 1000
	autocast.auto_range = 1000
	autocast.cooldown = 1
	autocast.mana_cost = 0
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast

	return [autocast]


func on_attack(_event: Event):
	var bounder_chance: float = 0.15 + 0.006 * tower.get_level()

	if !tower.calc_chance(bounder_chance):
		return

	ashbringer_bounder_throw()


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var storm_chance: float = 0.05 + 0.002 * tower.get_level()

	ashbringer_lacerate_damage(target, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit_no_bonus())
	event.damage = 0

	if !tower.calc_chance(storm_chance):
		return

	ashbringer_storm_throw(target)


func periodic(_event: Event):
	var damage: float = (0.5 + 0.01 * tower.get_level()) * tower.get_current_attack_damage_with_bonus()

	for glaivesaw in glaivesaw_list:
		var pos: Vector2 = glaivesaw.position

		var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), pos, 150)

		while true:
			var next: Unit = it.next()

			if next == null:
				break

			var effect: int = Effect.create_simple_on_unit("StampedeMissileDeath.mdl", next, Unit.BodyPart.ORIGIN)
			ashbringer_lacerate_damage(next, damage, tower.calc_attack_multicrit_no_bonus())
			Effect.set_lifetime(effect, 2.0)


func on_destruct():
	for glaivesaw in glaivesaw_list:
		var effect_id: int = glaivesaw.effect_id
		Effect.destroy_effect(effect_id)


func on_autocast(event: Event):
	var autocast: Autocast = event.get_autocast_type()
	var target_pos: Vector2 = autocast.get_target_pos()
	
	var new_glaive: Glaivesaw = Glaivesaw.new()
	var new_effect: int = Effect.create_animated_scaled("BloodElfSpellThiefMISSILE.mdl", Vector3(target_pos.x, target_pos.y, 40.0), 0.0, 1.45)
	Effect.set_animation_speed(new_effect, 2.0)
	Effect.set_scale(new_effect, 5)
	new_glaive.effect_id = new_effect
	new_glaive.position = target_pos

	glaivesaw_list.append(new_glaive)

#	Delete oldest glaive to keep total glaive count at 3
	while glaivesaw_list.size() > GLAIVESAW_MAX:
		var old_glaive: Glaivesaw = glaivesaw_list.pop_front()
		var effect: int = old_glaive.effect_id
		Effect.destroy_effect(effect)


func ashbringer_lacerate_damage(target: Unit, damage: float, crit: float):
	var dot_inc: float = 1.0 + 0.01 * tower.get_level()
	var dot_damage: float = 0.5 * damage * dot_inc * crit

	tower.do_attack_damage(target, damage * 0.5, crit)

	var buff: Buff = target.get_buff_of_type(lacerate_bt)

	if buff != null:
		var damage_stack: float = buff.user_real + dot_damage
		buff = lacerate_bt.apply(tower, target, 0)
		buff.user_real = damage_stack
	else:
		buff = lacerate_bt.apply(tower, target, 0)
		buff.user_real = dot_damage


func lacerate_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var remaining: float = buff.get_remaining_duration()
	var damage: float = buff.user_real / remaining
	var damage_tick: float = damage
#	NOTE: unused in original script, probably a bug
	# var movement_relative: float = target.get_current_movespeed() / 261

	if target.is_stunned():
		damage_tick = 0
	else:
		if remaining < 1:
			damage = buff.user_real
			damage_tick = damage

	if damage_tick > 0:
		buff.user_real -= damage
		tower.do_custom_attack_damage(target, damage_tick, 1.0, AttackType.enm.DECAY)


func ashbringer_bounder_throw():
	if glaivesaw_list.is_empty():
		return

	CombatLog.log_ability(tower, null, "Bounder")

	var damage: float = (2.5 + 0.06 * tower.get_level()) * tower.get_current_attack_damage_with_bonus()
	var random_glaivesaw_index: int = Globals.synced_rng.randi_range(0, glaivesaw_list.size() - 1)
	var random_glaivesaw: Glaivesaw = glaivesaw_list[random_glaivesaw_index]
	var bounces: int = 1

	var p: Projectile = Projectile.create_linear_interpolation_from_point_to_point(bounder_pt, tower, 0, 0, Vector3(tower.get_x(), tower.get_y(), 110), Vector3(random_glaivesaw.position.x, random_glaivesaw.position.y, 0), 0)
	p.user_int = random_glaivesaw_index
	p.user_int2 = bounces
	p.user_real = damage


func bounder_pt_on_collision(p: Projectile, target: Unit):
	var damage: float = p.user_real
	ashbringer_lacerate_damage(target, damage, tower.calc_attack_multicrit_no_bonus())


func bounder_pt_on_finished(p: Projectile, _target: Unit):
	var bounces: int = p.user_int2
	var bounce_is_over: bool = bounces == 0

	if bounce_is_over:
		return

# 	Pick random glaivesaw to bounce to, which is not the
# 	current glaivesaw
	var next_glaivesaw_list: Array = []

	for glaivesaw in glaivesaw_list:
		var glaivesaw_is_at_projectile: bool = glaivesaw.position == p.get_position_wc3_2d()
		
		if !glaivesaw_is_at_projectile:
			next_glaivesaw_list.append(glaivesaw)

	if next_glaivesaw_list.is_empty():
		return

	var next_glaivesaw: Glaivesaw = Utils.pick_random(Globals.synced_rng, next_glaivesaw_list)

	p.avert_destruction()
	p.start_bezier_interpolation_to_point(Vector3(next_glaivesaw.position.x, next_glaivesaw.position.y, 0), 0, 0, 0)
	bounces = 0
	p.user_int2 = bounces


func ashbringer_storm_throw(target: Unit):
	CombatLog.log_ability(tower, target, "Glaive Storm")
	var p: Projectile = Projectile.create_bezier_interpolation_from_unit_to_unit(storm_pt, tower, 1, 1, tower, target, 0, 0.3, 0.17, true)
	
	var damage: float = (0.5 + 0.02 * tower.get_level()) * tower.get_current_attack_damage_with_bonus()
	var hit_count: int = 20
	var moving_to_target: int = 1
	p.user_int = moving_to_target
	p.user_int2 = hit_count
	p.user_real = damage
	p.user_real2 = tower.get_x()
	p.user_real3 = tower.get_y()


func storm_pt_on_finished(p: Projectile, creep: Unit):
	var moving_to_target: int = p.user_int
	var bounce_count: int = p.user_int2
	var tower_x: float = p.user_real2
	var tower_y: float = p.user_real3
	var return_pos: Vector3 = Vector3(tower_x, tower_y, 100)

	if moving_to_target == 1:
		p.avert_destruction()
		var damage: float = p.user_real
		if creep != null:
			ashbringer_lacerate_damage(creep, damage, tower.calc_attack_multicrit_no_bonus())
		p.start_bezier_interpolation_to_point(return_pos, 0, 0.3, 0.17)
		moving_to_target = 0
		p.user_int = moving_to_target
	elif bounce_count > 0:
		var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), Vector2(tower_x, tower_y), 1000)
		var next: Unit = it.next_random()

		if next != null:
			p.avert_destruction()
			p.start_bezier_interpolation_to_unit(next, 0, 0.3, 0.17, true)

			moving_to_target = 1
			p.user_int = moving_to_target

			bounce_count -= 1
			p.user_int2 = bounce_count
