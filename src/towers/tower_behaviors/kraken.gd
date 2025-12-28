extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed bug where Kraken
# would crash the game. Not sure what caused the crash in
# original game, it got fixed naturally in youtd2.

# NOTE: changed how cooldown for tentacles is implemented.
# Original script keeps a reference to periodic timer and
# modifies it. Changed it to get rid of the need for
# reference to timer. Instead, periodic callback shortens
# it's own period when needed.


var stun_bt: BuffType
var acid_goo_bt: BuffType
var last_tick_when_used_tentacles: int = 0
var TARGET_TYPE_GROUND_ONLY: TargetType = TargetType.new(TargetType.CREEPS + TargetType.SIZE_MASS + TargetType.SIZE_NORMAL + TargetType.SIZE_CHAMPION + TargetType.SIZE_BOSS)


const ACID_GOO_CHANCE: float = 0.30
const ACID_GOO_CHANCE_ADD: float = 0.01
const ACID_GOO_ARMOR: float = 15.0
const ACID_GOO_ARMOR_ADD: float = 0.6
const ACID_GOO_DURATION: float = 5.0
const ACID_GOO_DURATION_ADD: float = 0.2

const EAT_THE_DEAD_VALUES: Dictionary = {
	CreepSize.enm.MASS: 0.005,
	CreepSize.enm.NORMAL: 0.01,
	CreepSize.enm.AIR: 0.02,
	CreepSize.enm.CHAMPION: 0.02,
	CreepSize.enm.BOSS: 0.10,
}

const TENTACLE_ATTACK_RADIUS: float = 1200
const TENTACLE_ATTACK_CD: float = 4.0
const TENTACLE_ATTACK_CD_ADD: float = -0.04
const TENTACLE_ATTACK_TENTACLE_COUNT: int = 6
const TENTACLE_ATTACK_DAMAGE_RATIO: float = 0.15
const TENTACLE_ATTACK_STUN_DURATION: float = 0.4


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_kill(on_kill)
	triggers_buff_type.add_event_on_damage(on_damage)
	triggers_buff_type.add_periodic_event(periodic, 4.0)
	triggers_buff_type.add_event_on_unit_comes_in_range(on_unit_in_range, TENTACLE_ATTACK_RADIUS, TargetType.new(TargetType.CREEPS))


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)

	acid_goo_bt = BuffType.new("acid_goo_bt", ACID_GOO_DURATION, ACID_GOO_DURATION_ADD, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ARMOR, -ACID_GOO_ARMOR, -ACID_GOO_ARMOR_ADD)
	acid_goo_bt.set_buff_modifier(mod)
	acid_goo_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	acid_goo_bt.set_buff_tooltip(tr("L7ND"))


func on_kill(event: Event):
	var target: Creep = event.get_target()
	var target_size: CreepSize.enm = target.get_size()

	var mod_value: float = EAT_THE_DEAD_VALUES.get(target_size, 0)
	tower.modify_property(ModificationType.enm.MOD_DAMAGE_BASE_PERC, mod_value)

	var effect: int = Effect.create_simple_at_unit("res://src/effects/blood_splatter.tscn", target)
	Effect.set_scale(effect, 2)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	var chance: float = ACID_GOO_CHANCE + ACID_GOO_CHANCE_ADD * level

	if !tower.calc_chance(chance):
		return

	CombatLog.log_ability(tower, target, "Acid Goo")

	acid_goo_bt.apply(tower, target, level)


# NOTE: need to adjust periodic timer because tentacles can
# be also fired inside on_unit_in_range().
func periodic(event: Event):
	var tentacles_are_on_cd: bool = get_tentacles_are_on_cd()

	if tentacles_are_on_cd:
		var tentacles_cd: float = get_tentacles_cd()
		var tentacles_cd_ticks: int = Utils.time_to_ticks(tentacles_cd)
		var current_tick: int = Utils.get_current_tick()
		var tick_for_next_tentacles: int = last_tick_when_used_tentacles + tentacles_cd_ticks
		var remaining_cd_ticks: int = tick_for_next_tentacles - current_tick
		var remaining_cd: float = Utils.ticks_to_time(remaining_cd_ticks)

		event.enable_advanced(remaining_cd, false)
	else:
		fire_tentacles()

		var tentacles_cd: float = get_tentacles_cd()
		event.enable_advanced(tentacles_cd, false)


func on_unit_in_range(_event: Event):
	var tentacles_are_on_cd: bool = get_tentacles_are_on_cd()

	if !tentacles_are_on_cd:
		fire_tentacles()


func fire_tentacles():
	var level: int = tower.get_level()

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TARGET_TYPE_GROUND_ONLY, TENTACLE_ATTACK_RADIUS)

	var tentacle_count_max: int = TENTACLE_ATTACK_TENTACLE_COUNT
	if level == 25:
		tentacle_count_max += 2
	elif level >= 15:
		tentacle_count_max += 1

	var tentacle_count: int = 0

	var tentacle_damage: float = TENTACLE_ATTACK_DAMAGE_RATIO * tower.get_current_attack_damage_with_bonus()

	if it.count() > 0:
		CombatLog.log_ability(tower, null, "Tentacle Attack")

	while true:
		if tentacle_count >= tentacle_count_max:
			break

		var target: Unit = it.next_random()
		
		if target == null:
			break
		
		var random_offset: Vector2 = Vector2(Globals.synced_rng.randf_range(-35, 35), Globals.synced_rng.randf_range(-35, 35))
		var effect_pos: Vector2 = target.get_position_wc3_2d() + random_offset
		Effect.add_special_effect("res://src/effects/impale_hit_target.tscn", effect_pos)

		stun_bt.apply_only_timed(tower, target, TENTACLE_ATTACK_STUN_DURATION)

		tower.do_custom_attack_damage(target, tentacle_damage, tower.calc_attack_multicrit_no_bonus(), AttackType.enm.PHYSICAL)

		tentacle_count += 1

	var created_any_tentacles: bool = tentacle_count > 0
	if created_any_tentacles:
		last_tick_when_used_tentacles = Utils.get_current_tick()


func get_tentacles_cd() -> float:
	var level: int = tower.get_level()
	var cd: float = TENTACLE_ATTACK_CD + TENTACLE_ATTACK_CD_ADD * level

	return cd


func get_tentacles_are_on_cd() -> bool:
	var tentacles_cd: float = get_tentacles_cd()
	var tentacles_cd_ticks: int = Utils.time_to_ticks(tentacles_cd)
	var current_tick: int = Utils.get_current_tick()
	var ticks_since_last_tentacles: int = current_tick - last_tick_when_used_tentacles
	var tentacles_are_on_cd: bool = ticks_since_last_tentacles < tentacles_cd_ticks

	return tentacles_are_on_cd
