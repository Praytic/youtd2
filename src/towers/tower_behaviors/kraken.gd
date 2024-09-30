extends TowerBehavior


# NOTE: changed how cooldown for tentacles is implemented.
# Original script keeps a reference to periodic timer and
# modifies it. Changed it to get rid of the need for
# reference to timer. Instead, periodic callback shortens
# it's own period when needed.


var stun_bt: BuffType
var acid_goo_bt: BuffType
var last_time_when_used_tentacles: float = 0.0
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


func get_ability_info_list() -> Array[AbilityInfo]:
	var acid_goo_chance: String = Utils.format_percent(ACID_GOO_CHANCE, 2)
	var acid_goo_chance_add: String = Utils.format_percent(ACID_GOO_CHANCE_ADD, 2)
	var acid_goo_armor: String = Utils.format_float(ACID_GOO_ARMOR, 2)
	var acid_goo_armor_add: String = Utils.format_float(ACID_GOO_ARMOR_ADD, 2)
	var acid_goo_duration: String = Utils.format_float(ACID_GOO_DURATION, 2)
	var acid_goo_duration_add: String = Utils.format_float(ACID_GOO_DURATION_ADD, 2)

	var eat_the_dead_mass: String = Utils.format_percent(EAT_THE_DEAD_VALUES[CreepSize.enm.MASS], 2)
	var eat_the_dead_normal: String = Utils.format_percent(EAT_THE_DEAD_VALUES[CreepSize.enm.NORMAL], 2)
	var eat_the_dead_champion: String = Utils.format_percent(EAT_THE_DEAD_VALUES[CreepSize.enm.CHAMPION], 2)
	var eat_the_dead_air: String = Utils.format_percent(EAT_THE_DEAD_VALUES[CreepSize.enm.AIR], 2)
	var eat_the_dead_boss: String = Utils.format_percent(EAT_THE_DEAD_VALUES[CreepSize.enm.BOSS], 2)

	var tentacle_attack_cd: String = Utils.format_float(TENTACLE_ATTACK_CD, 2)
	var tentacle_attack_cd_add: String = Utils.format_float(TENTACLE_ATTACK_CD_ADD, 2)
	var tentacle_attack_tentacle_count: String = Utils.format_float(TENTACLE_ATTACK_TENTACLE_COUNT, 2)
	var tentacle_attack_damage_ratio: String = Utils.format_percent(TENTACLE_ATTACK_DAMAGE_RATIO, 2)
	var tentacle_attack_stun_duration: String = Utils.format_float(TENTACLE_ATTACK_STUN_DURATION, 2)
	var physical_string: String = AttackType.convert_to_colored_string(AttackType.enm.PHYSICAL)

	var list: Array[AbilityInfo] = []

	var eat_the_dead: AbilityInfo = AbilityInfo.new()
	eat_the_dead.name = "Eat the Dead"
	eat_the_dead.icon = "res://resources/icons/undead/skull_01.tres"
	eat_the_dead.description_short = "Kraken gains a permanent increase in base attack damage on kill.\n"
	eat_the_dead.description_full = "Kraken gains a permanent increase in base attack damage on kill:\n" \
	+ "+%s for mass creeps\n" % eat_the_dead_mass \
	+ "+%s for normal creeps\n" % eat_the_dead_normal \
	+ "+%s for champions\n" % eat_the_dead_champion \
	+ "+%s for air creeps\n" % eat_the_dead_air \
	+ "+%s for bosses\n" % eat_the_dead_boss \
	+ ""
	list.append(eat_the_dead)

	var acid_goo: AbilityInfo = AbilityInfo.new()
	acid_goo.name = "Acid Goo"
	acid_goo.icon = "res://resources/icons/tower_icons/mossy_acid_sprayer.tres"
	acid_goo.description_short = "Chance to decrease armor of hit creeps.\n"
	acid_goo.description_full = "%s chance to decrease armor of hit creeps by %s for %s seconds.\n" % [acid_goo_chance, acid_goo_armor, acid_goo_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s seconds\n" % acid_goo_duration_add \
	+ "+%s armor decrease\n" % acid_goo_armor_add \
	+ "+%s chance\n" % acid_goo_chance_add \
	+ ""
	list.append(acid_goo)

	var tentacle_attack: AbilityInfo = AbilityInfo.new()
	tentacle_attack.name = "Tentacle Attack"
	tentacle_attack.icon = "res://resources/icons/clubs/club_glowing.tres"
	tentacle_attack.description_short = "Periodically stuns and deals a percentage of current attack damage to nearby non-flying creeps.\n"
	tentacle_attack.description_full = "Every %s seconds, the Kraken attacks random ground creeps with %s tentacles. Each tentacle deals %s of Kraken's current attack damage as %s damage and stuns for %s seconds.\n" % [tentacle_attack_cd, tentacle_attack_tentacle_count, tentacle_attack_damage_ratio, physical_string, tentacle_attack_stun_duration]\
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "%s seconds cooldown\n" % tentacle_attack_cd_add \
	+ "+1 tentacle on levels 15 and 25\n" \
	+ ""
	tentacle_attack.radius = TENTACLE_ATTACK_RADIUS
	tentacle_attack.target_type = TargetType.new(TargetType.CREEPS)
	list.append(tentacle_attack)

	return list


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, 0.1, 0.01)
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.02)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)

	acid_goo_bt = BuffType.new("acid_goo_bt", ACID_GOO_DURATION, ACID_GOO_DURATION_ADD, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ARMOR, -ACID_GOO_ARMOR, -ACID_GOO_ARMOR_ADD)
	acid_goo_bt.set_buff_modifier(mod)
	acid_goo_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	acid_goo_bt.set_buff_tooltip("Acid Goo\nDecreases armor.")


func on_kill(event: Event):
	var target: Creep = event.get_target()
	var target_size: CreepSize.enm = target.get_size()

	var mod_value: float = EAT_THE_DEAD_VALUES.get(target_size, 0)
	tower.modify_property(Modification.Type.MOD_DAMAGE_BASE_PERC, mod_value)

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
		var time_for_next_tentacles: float = last_time_when_used_tentacles + tentacles_cd
		var remaining_cd: float = time_for_next_tentacles - Utils.get_time()

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
		last_time_when_used_tentacles = Utils.get_time()


func get_tentacles_cd() -> float:
	var level: int = tower.get_level()
	var cd: float = TENTACLE_ATTACK_CD + TENTACLE_ATTACK_CD_ADD * level

	return cd


func get_tentacles_are_on_cd() -> bool:
	var tentacles_cd: float = get_tentacles_cd()
	var time_since_last_tentacles: float = Utils.get_time() - last_time_when_used_tentacles
	var tentacles_are_on_cd: bool = time_since_last_tentacles < tentacles_cd

	return tentacles_are_on_cd
