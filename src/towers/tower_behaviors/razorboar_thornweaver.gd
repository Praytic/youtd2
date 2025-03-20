extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Renamed
# "Quillboar Thornweaver"=>"Razorboar Thornweaver"


var thornspray_pt: ProjectileType
var thorns_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {occasional_thornspray_chance = 0.12, occasional_thornspray_chance_add = 0.0015, double_chance = 0.05, triple_chance = 0.03},
		2: {occasional_thornspray_chance = 0.15, occasional_thornspray_chance_add = 0.0018, double_chance = 0.07, triple_chance = 0.05},
		3: {occasional_thornspray_chance = 0.18, occasional_thornspray_chance_add = 0.0021, double_chance = 0.09, triple_chance = 0.07},
	}


const QUILLSPRAY_STACKS_MAX: int = 40
const QUILLSPRAY_STACK_BONUS: float = 0.11
const QUILLSPRAY_DAMAGE_RATIO: float = 0.30
const QUILLSPRAY_DAMAGE_RATIO_ADD: float = 0.002
const QUILLSPRAY_DEBUFF_DURATION: float = 1.5
const QUILLSPRAY_RANGE: float = 800


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	thorns_bt = BuffType.new("thorns_bt", QUILLSPRAY_DEBUFF_DURATION, 0, false, self)
	thorns_bt.set_buff_icon("res://resources/icons/generic_icons/polar_star.tres")
	thorns_bt.set_buff_tooltip("Thorns\nIncreases attack damage taken when hit by Thornspray.")

	thornspray_pt = ProjectileType.create("res://src/projectiles/projectile_visuals/quillspray_projectile.tscn", 2, 1300, self)
	thornspray_pt.enable_homing(on_projectile_hit, 0)


func on_attack(_event: Event):
	var level: int = tower.get_level()
	var chance: float = _stats.occasional_thornspray_chance + _stats.occasional_thornspray_chance_add * level

	if !tower.calc_chance(chance):
		return

	CombatLog.log_ability(tower, null, "Occasional Thornspray")

	do_thornspray_series()


func on_autocast(_event: Event):
	do_thornspray_series()


func on_projectile_hit(_projectile: Projectile, target: Unit):
	if target == null:
		return
	
	var level: int = tower.get_level()

	var active_buff: Buff = target.get_buff_of_type(thorns_bt)

	var active_stacks: int
	if active_buff != null:
		active_stacks = active_buff.user_int
	else:
		active_stacks = 0

	var thorns_multiplier: float = pow(1.0 + QUILLSPRAY_STACK_BONUS, active_stacks)
	var damage_ratio: float = (QUILLSPRAY_DAMAGE_RATIO + QUILLSPRAY_DAMAGE_RATIO_ADD * level) * thorns_multiplier
	var damage: float = damage_ratio * tower.get_current_attack_damage_with_bonus()

	tower.do_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus())

	var new_stacks: int = min(active_stacks + 1, QUILLSPRAY_STACKS_MAX)

#	NOTE: weaker tier tower increases buff effect without
#	refreshing duration
	active_buff = thorns_bt.apply(tower, target, 1)
	active_buff.user_int = new_stacks
	active_buff.set_displayed_stacks(new_stacks)


func do_thornspray_series():
	var level: int = tower.get_level()

	thornspray(1350)

	if level == 25:
		if tower.calc_chance(_stats.triple_chance):
			CombatLog.log_ability(tower, null, "Tripple Thornspray")
			thornspray(1500)
			thornspray(1700)
		else:
			CombatLog.log_ability(tower, null, "Double Thornspray")
			thornspray(1500)
	elif level > 15:
		if tower.calc_chance(_stats.double_chance):
			CombatLog.log_ability(tower, null, "Double Thornspray")
			thornspray(1500)


func thornspray(speed: float):
	var creeps_in_range: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), QUILLSPRAY_RANGE)

	while true:
		var creep: Unit = creeps_in_range.next()

		if creep == null:
			break

		var projectile: Projectile = Projectile.create_from_unit_to_unit(thornspray_pt, tower, 1.0, 1.0, tower, creep, true, false, false)
		projectile.set_projectile_scale(0.7)
		projectile._speed = speed
