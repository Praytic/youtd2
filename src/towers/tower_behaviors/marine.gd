extends TowerBehavior


var stim_bt: BuffType
var fragged_bt: BuffType
var shard_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {grenade_chance = 0.20, grenade_chance_add = 0.003, grenade_count = 6, grenade_damage = 1200, grenade_damage_add = 100},
		2: {grenade_chance = 0.25, grenade_chance_add = 0.004, grenade_count = 8, grenade_damage = 1800, grenade_damage_add = 150},
	}

const STIM_ATTACKSPEED: float = 1.5
const STIM_ATTACK_DMG: float = 0.5
const STIM_DURATION: float = 5
const STIM_DURATION_ADD: float = 0.08
const GRENADE_MOD_DMG_RECEIVED: float = 0.02
const GRENADE_MOD_DMG_RECEIVED_ADD: float = 0.001
const GRENADE_MOD_DMG_RECEIVED_MAX: float = 0.50


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	stim_bt = BuffType.new("stim_bt", STIM_DURATION, STIM_DURATION_ADD, true, self)
	var boekie_stim_mod: Modifier = Modifier.new()
	boekie_stim_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, STIM_ATTACKSPEED, 0.0)
	boekie_stim_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, -STIM_ATTACK_DMG, 0.0)
	stim_bt.set_buff_modifier(boekie_stim_mod)
	stim_bt.set_buff_icon("res://resources/icons/generic_icons/meat.tres")
	stim_bt.set_buff_tooltip("Stim\nIncreases attack speed and decreases attack damage.")

	fragged_bt = BuffType.new("fragged_bt", -1, 0, true, self)
	var boekie_grenade_mod: Modifier = Modifier.new()
	boekie_grenade_mod.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, GRENADE_MOD_DMG_RECEIVED, GRENADE_MOD_DMG_RECEIVED_ADD)
	fragged_bt.set_buff_modifier(boekie_grenade_mod)
	fragged_bt.set_buff_icon("res://resources/icons/generic_icons/ankh.tres")
	fragged_bt.set_buff_tooltip("Fragged\nIncreases attack damage taken.")

	shard_pt = ProjectileType.create_ranged("path_to_projectile_sprite", 400, 500, self)
	shard_pt.set_event_on_expiration(boekie_shard_on_expiration)
	shard_pt.enable_collision(boekie_shard_on_collide, 75, TargetType.new(TargetType.CREEPS), true)


func on_damage(event: Event):
	var grenade_chance: float = _stats.grenade_chance + _stats.grenade_chance_add * tower.get_level()

	if !tower.calc_chance(grenade_chance):
		return

	CombatLog.log_ability(tower, null, "Frag Grenade")

	var projectile: Projectile = Projectile.create_from_unit_to_unit(shard_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), tower, event.get_target(), false, true, false)
#	Set user_int to 1 to mark this grenade as "main grenade"
	projectile.user_int = 1


func on_autocast(_event: Event):
	var level: int = tower.get_level()
	stim_bt.apply(tower, tower, level)


func boekie_shard_on_collide(projectile: Projectile, target: Unit):
	var level: int = tower.get_level()
	var buff: Buff = target.get_buff_of_type(fragged_bt)

	var grenade_damage: float = _stats.grenade_damage + _stats.grenade_damage_add * level
	projectile.do_spell_damage(target, grenade_damage)

	Effect.create_simple_at_unit("res://src/effects/frag_boom_spawn.tscn", target)

	if buff != null:
		var buff_level: int = int(min(480, buff.get_level() + 20 + level))
		fragged_bt.apply(tower, target, buff_level)
	else:
		fragged_bt.apply(tower, target, level)

#	NOTE: need to add 2 to displayed stacks because fragged
#	buff applies 2% at buff level 0
	buff = target.get_buff_of_type(fragged_bt)
	if buff != null:
		var stack_count: int = buff.get_level() / 10 + 2
		buff.set_displayed_stacks(stack_count)


func boekie_shard_on_expiration(projectile: Projectile):
	var CONE_WIDTH: float = 120
	var num_projectiles: float = _stats.grenade_count
	var angle: float = projectile.get_direction() - CONE_WIDTH / 2
	var dmg_ratio: float = projectile.get_dmg_ratio()
	var is_main_grenade: bool = projectile.user_int == 1

	if !is_main_grenade:
		return

	for i in range(0, num_projectiles):
		var small_grenade: Projectile = Projectile.create(shard_pt, tower, dmg_ratio, tower.calc_spell_crit_no_bonus(), projectile.get_position_wc3(), angle + Globals.synced_rng.randf_range(-8, 8))
#		Set user_int to 0 to mark this grenade as "not main"
#		and stop recursion
		small_grenade.user_int = 0
		angle += CONE_WIDTH / (num_projectiles - 1)
