extends TowerBehavior


# NOTE: original script used a weird method of storing and
# manipulating Icicle structs. Changed to a different method
# which is less complex.


class Icicle:
	var projectile: Projectile
	var effect: int
	var position: Vector2


const ICICLE_MAX_BASE: int = 5


var stun_bt: BuffType
var frostburn_bt: BuffType
var shatter_bt: BuffType
var icicle_bt: BuffType
var bombardment_pt: ProjectileType
var icicle_prop_pt: ProjectileType
var icicle_missile_pt: ProjectileType

var icicle_list: Array[Icicle]
var fired_icicle_count: int = 0
var fire_all_in_progress: bool = false
var prev_stored_icicle_angle: float = 0.0


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	# and 
	var icicles: AbilityInfo = AbilityInfo.new()
	icicles.name = "Icicles"
	icicles.icon = "res://resources/icons/gems/gem_03.tres"
	icicles.description_short = "Whenever this tower hits a creep, it has a chance to create [color=GOLD]Icicles[/color]. [color=GOLD]Icicles[/color] increase tower's attack damage and mana regen. When [color=GOLD]Icicles[/color] are fired they deal [color=GOLD]Frostburn[/color] damage.\n"
	icicles.description_full = "Whenever this tower hits a creep, it has a 15% chance to create an [color=GOLD]Icicle[/color]. [color=GOLD]Icy Bombardments[/color] also has a 5% chance to create an [color=GOLD]Icicle[/color]. [color=GOLD]Icicles[/color] are stored and passively increase attack damage by 5% and mana regen by 0.5 mana per second each. Maximum of 5 [color=GOLD]Icicles[/color]. At maximum [color=GOLD]Icicles[/color], any extra [color=GOLD]Icicles[/color] created are instantly fired at the target. Each [color=GOLD]Icicle[/color] deals 3000 [color=GOLD]Frostburn[/color] damage and permanently increases the damage dealt by future [color=GOLD]Icicles[/color] from this tower by 2%.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% chance on attack\n" \
	+ "+0.1% chance on Icy Bombardment\n" \
	+ "+80 damage\n" \
	+ "+1 max icicle every 5 levels\n"
	list.append(icicles)

	var icy_bobmardment: AbilityInfo = AbilityInfo.new()
	icy_bobmardment.name = "Icy Bombardment"
	icy_bobmardment.icon = "res://resources/icons/trinkets/claw_03.tres"
	icy_bobmardment.description_short = "Whenever this tower attacks, it has a chance to fire a projectile at a random point which deals AoE [color=GOLD]Frostburn[/color] damage.\n"
	icy_bobmardment.description_full = "Whenever this tower attacks, it has a 15% chance to fire a projectile at a random point within 150 range of the attacked creep that deals 25% of current attack damage as [color=GOLD]Frostburn[/color] damage in 200 AoE splash. Each additional projectile has a 30% chance to fire another, up to a maximum of 4 per attack.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% initial chance\n" \
	+ "+0.4% additional chance\n" \
	+ "+0.6% damage\n"
	list.append(icy_bobmardment)

	var frostburn: AbilityInfo = AbilityInfo.new()
	frostburn.name = "Frostburn"
	frostburn.icon = "res://resources/icons/fire/flame_blue_glowing.tres"
	frostburn.description_short = "This tower's attacks and abilities deal [color=GOLD]Frostburn[/color] damage. The damage is split into attack damage and spell damage over time.\n"
	frostburn.description_full = "This tower's attacks and abilities deal [color=GOLD]Frostburn[/color] damage. 50% of the damage is dealt immediately as attack damage. 100% of the remaining damage is dealt as spell damage over 5 seconds. If this effect is reapplied, any remaining damage will be added to the new duration.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% damage over time\n"
	list.append(frostburn)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)

	frostburn_bt = BuffType.new("frostburn_bt", 5, 0, false, self)
	frostburn_bt.set_buff_icon("res://resources/icons/generic_icons/burning_dot.tres")
	frostburn_bt.add_periodic_event(frostburn_bt_periodic, 1.0)
	frostburn_bt.set_buff_tooltip("Frostburn\nDeals damage over time.")

	shatter_bt = BuffType.new("shatter_bt", 5, 0, false, self)
	shatter_bt.set_buff_icon("res://resources/icons/generic_icons/polar_star.tres")
	var ashbringer_ebonfrost_shatter_mod: Modifier = Modifier.new()
	ashbringer_ebonfrost_shatter_mod.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, 0.0, 1.0)
	ashbringer_ebonfrost_shatter_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.0, 1.0)
	shatter_bt.set_buff_modifier(ashbringer_ebonfrost_shatter_mod)
	shatter_bt.add_event_on_create(shatter_bt_on_create)
	shatter_bt.set_buff_tooltip("Shatter\nIncreases attack and spell damage taken.")

	icicle_bt = BuffType.new("icicle_bt", -1, 0, true, self)
	var ashbringer_ebonfrost_icicle_mod: Modifier = Modifier.new()
	ashbringer_ebonfrost_icicle_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.05)
	ashbringer_ebonfrost_icicle_mod.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, 0.5)
	icicle_bt.set_buff_modifier(ashbringer_ebonfrost_icicle_mod)
	icicle_bt.set_buff_icon("res://resources/icons/generic_icons/azul_flake.tres")
	icicle_bt.set_buff_tooltip("Icicle\nIncreases attack damage and mana regeration.")

# 	NOTE: in original script, this ProjectileType.create()
# 	is called here but this ProjectileType is later used as
# 	an interpolated projectile. Changed to use
# 	create_interpolate().
	bombardment_pt = ProjectileType.create_interpolate("FrostWyrmMissile.mdl", 1650, self)
	bombardment_pt.set_event_on_cleanup(bombardment_pt_on_hit)

	icicle_prop_pt = ProjectileType.create_interpolate("FrostBoltMissile.mdl", 200, self)
	icicle_prop_pt.set_event_on_interpolation_finished(icicle_prop_pt_on_finished)
	icicle_prop_pt.disable_explode_on_expiration()

	icicle_missile_pt = ProjectileType.create("FrostBoltMissile.mdl", 5, 1400, self)
	icicle_missile_pt.enable_homing(icicle_missile_pt_on_hit, 0)


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	autocast.title = "Shattering Barrage"
	autocast.icon = "res://resources/icons/tower_variations/MeteorTotem_blue.tres"
	autocast.description_short = "Spends all mana to encase the target in ice.\n"
	autocast.description = "Spends all mana to encase the target in ice, stunning it and increasing all damage taken by 100% for up to [mana / 150] seconds. All icicles are then fired at the target. Duration is reduced by 75% on Bosses, to a minimum of 2 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "-1 mana divisor\n"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 1000
	autocast.auto_range = 750
	autocast.cooldown = 30
	autocast.mana_cost = 300
	autocast.target_self = false
	autocast.is_extended = true
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast

	return [autocast]


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var icy_bombardment_chance: float = 0.15 + 0.004 * tower.get_level()

	if !tower.calc_chance(icy_bombardment_chance):
		return

	CombatLog.log_ability(tower, target, "Icy Bombardment")
	ashbringer_icy_bombardment(target)


func on_damage(event: Event):
	var target: Creep = event.get_target()
	var damage: float = event.damage
	var icicle_chance: float = 0.15 + 0.004 * tower.get_level()

	ashbringer_frostburn_damage(target, damage)
	event.damage = 0

	if tower.calc_chance(icicle_chance):
		CombatLog.log_ability(tower, target, "Icicle")
		ashbringer_icicle_create(target)


func on_destruct():
	for icicle in icicle_list:
		var projectile: Projectile = icicle.projectile
		projectile.remove_from_game()

		var effect: int = icicle.effect
		Effect.destroy_effect(effect)

	icicle_list.clear()


func on_autocast(event: Event):
	var target: Creep = event.get_target()
	var tower_mana: float = tower.get_mana()
	var duration: float = tower_mana / (150 - tower.get_level())

	if target.get_size() == CreepSize.enm.BOSS:
		duration *= 0.25

		if duration < 2.0:
			duration = 2.0

	shatter_bt.apply_custom_timed(tower, target, tower.get_level(), duration)
	tower.subtract_mana(tower_mana, true)


# NOTE: this Icicle is fired straight from the tower so we
# don't need to clean up it's effect or remove it from
# icicle list because that setup was never performed for it.
func ashbringer_icicle_fire_single(target: Unit):
	var start_pos: Vector3 = tower.get_position_wc3()
	
	CombatLog.log_ability(tower, target, "Fire single Icicle")
	var p: Projectile = Projectile.create_from_point_to_unit(icicle_missile_pt, tower, 0, 0, start_pos, target, true, false, false)
	p.set_projectile_scale(0.7)

	fired_icicle_count += 1


# NOTE: original script performs complex logic to have
# position "slots" for each icicle. Replaced this logic with
# simpler version where new icicles are placed in a rotating
# fashion. Position of new icicle = position of prev icicle
# slightly rotated.
func ashbringer_icicle_store():
	var icicle_count_max: int = get_icicle_count_max()

	CombatLog.log_ability(tower, null, "Store Icicle - %d" % icicle_list.size())

# 	NOTE: original script does this in a different way more
# 	complicated way. Changed to this simpler method which
# 	achieves almost the same result.
	var angle: float = prev_stored_icicle_angle + 360 / icicle_count_max
	prev_stored_icicle_angle = angle

	var offset: Vector2 = Vector2(100, 0).rotated(deg_to_rad(angle))
	var start_pos: Vector3 = Vector3(tower.get_x(), tower.get_y(), 200)
	var icicle_pos: Vector3 = Vector3(tower.get_x() + offset.x, tower.get_y() + offset.y, 200)
	var p: Projectile = Projectile.create_linear_interpolation_from_point_to_point(icicle_prop_pt, tower, 1.0, 0.0, start_pos, icicle_pos, 0.0)
	p.set_projectile_scale(0.7)
	p.user_real = icicle_pos.x
	p.user_real2 = icicle_pos.y
	p.user_real3 = angle

	var icicle: Icicle = Icicle.new()
	icicle.projectile = p
	icicle.position = VectorUtils.vector3_to_vector2(icicle_pos)
	icicle_list.append(icicle)

	icicle_bt.apply(tower, tower, icicle_list.size())


func icicle_prop_pt_on_finished(p: Projectile, _target: Unit):
	var icicle_x: float = p.user_real
	var icicle_y: float = p.user_real2
	var angle: float = p.user_real3

	var icicle: Icicle = null

	for the_icicle in icicle_list:
		if the_icicle.projectile == p:
			icicle = the_icicle

	if icicle == null:
		return

#	NOTE: added this call, doesn't exist in original script.
#	I think maybe in JASS engine interpolated projectiles
#	without target unit are not destroyed when they reached
#	the target point?
	p.avert_destruction()

	var effect: int = Effect.create_scaled("res://src/effects/StunVisual.tscn", Vector3(icicle_x, icicle_y, 200), angle, 5)
	icicle.effect = effect


func ashbringer_icicle_create(target: Unit):
	var icicle_count: int = icicle_list.size()
	var icicle_count_max: int = get_icicle_count_max()
	var have_icicle_space: bool = icicle_count < icicle_count_max
	var should_store_icicle: bool = have_icicle_space && !fire_all_in_progress

	if should_store_icicle:
		ashbringer_icicle_store()
	else:
		ashbringer_icicle_fire_single(target)


func ashbringer_frostburn_damage(target: Unit, damage: float):
	var dot_inc = 1.0 + 0.01 * tower.get_level()

	tower.do_attack_damage(target, damage * 0.5, tower.calc_attack_multicrit_no_bonus())

	var old_buff: Buff = target.get_buff_of_type(frostburn_bt)

	var dot_damage: float = damage * 0.5 * dot_inc
	if old_buff != null:
		dot_damage += old_buff.user_real

	var new_buff: Buff = frostburn_bt.apply(tower, target, 0)
	new_buff.user_real = dot_damage


func frostburn_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Creep = buff.get_buffed_unit()
	var remaining: float = buff.get_remaining_duration()
	var damage_tick: float = buff.user_real / remaining

	if remaining < 1:
		damage_tick = buff.user_real

	if damage_tick > 0:
		buff.user_real -= damage_tick
		tower.do_spell_damage(target, damage_tick, tower.calc_spell_crit_no_bonus())


func icicle_missile_pt_on_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	var damage: float = (3000 + 80 * tower.get_level()) * (1.0 + 0.02 * fired_icicle_count)

	ashbringer_frostburn_damage(target, damage)


func ashbringer_icicle_fire_all(target: Unit):
#	Set this flag so that any icicles created while this
#	function is running are fired instantly. Icicles may be
#	created because of ON_DAMAGE event.
	fire_all_in_progress = true

	CombatLog.log_ability(tower, target, "Fire all Icicles - %d" % icicle_list.size())

	while !icicle_list.is_empty():
		var icicle: Icicle = icicle_list.pop_front()

		var start_pos: Vector3 = Vector3(icicle.position.x, icicle.position.y, 200)
		var icicle_missile: Projectile = Projectile.create_from_point_to_unit(icicle_missile_pt, tower, 0, 0, start_pos, target, true, false, false)
		icicle_missile.set_projectile_scale(0.7)
		icicle_missile.set_speed(1400 - 70 * icicle_list.size())
		fired_icicle_count += 1

		icicle.projectile.remove_from_game()
		Effect.destroy_effect(icicle.effect)
		
		icicle_list.erase(icicle)

	var buff: Buff = tower.get_buff_of_type(icicle_bt)
	if buff != null:
		buff.remove_buff()

	fire_all_in_progress = false


func ashbringer_icy_bombardment(target: Unit):
	var chance: float = 0.3 + 0.004 * tower.get_level()
	var shot_count: int = 0
	var target_pos: Vector2 = target.get_position_wc3_2d()

	while true:
		var random_angle: float = deg_to_rad(Globals.synced_rng.randf_range(0, 360))
		var random_distance: float = Globals.synced_rng.randf_range(0, 150)
		var offset: Vector2 = Vector2(random_distance, 0).rotated(random_angle)
		var launch_pos_2d: Vector2 = target_pos + offset
		var launch_pos: Vector3 = Vector3(launch_pos_2d.x, launch_pos_2d.y, 0)
		var p: Projectile = Projectile.create_linear_interpolation_from_point_to_point(bombardment_pt, tower, 0, 0, Vector3(tower.get_x(), tower.get_y(), 200), launch_pos, 0.2)
		p.user_real = launch_pos.x
		p.user_real2 = launch_pos.y

		shot_count += 1

		if !tower.calc_chance(chance) || shot_count >= 4:
			break


func bombardment_pt_on_hit(p: Projectile):
	var launch_x: float = p.user_real
	var launch_y: float = p.user_real2
	var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), Vector2(launch_x, launch_y), 200)
	var damage: float = tower.get_current_attack_damage_with_bonus() * (0.25 + 0.006 * tower.get_level())
	var icicle_chance: float = 0.05 + 0.001 * tower.get_level()

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		ashbringer_frostburn_damage(next, damage)

		if tower.calc_chance(icicle_chance):
			ashbringer_icicle_create(next)


func shatter_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var target: Creep = buff.get_buffed_unit()

	stun_bt.apply_only_timed(caster, target, buff.get_remaining_duration())
	ashbringer_icicle_fire_all(target)


func get_icicle_count_max() -> int:
	var bonus_from_lvls: int = floori(tower.get_level() / 5) 
	var count: int = ICICLE_MAX_BASE + bonus_from_lvls

	return count
