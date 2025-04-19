extends TowerBehavior

var stun_bt: BuffType
var fatigue_bt: BuffType
var axe_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {smashing_axe_dmg = 0.20, smashing_axe_dmg_add = 0.004, coated_axes_dmg = 0.0060, coated_axes_dmg_add = 0.00020},
		2: {smashing_axe_dmg = 0.25, smashing_axe_dmg_add = 0.005, coated_axes_dmg = 0.0065, coated_axes_dmg_add = 0.00025},
		3: {smashing_axe_dmg = 0.30, smashing_axe_dmg_add = 0.006, coated_axes_dmg = 0.0070, coated_axes_dmg_add = 0.00030},
	}

const ON_ATTACK_CHANCE: float = 0.15
const STUN_DURATION: float = 1.5
const STUN_DURATION_FOR_BOSSES: float = 0.75
const MOD_ATTACKSPEED: float = 0.30
const MOD_ATTACKSPEED_ADD: float = 0.004
const FATIGUE_DURATION: float = 3
const PURGE_COUNT_FOR_STUN: float = 5


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)
	
	fatigue_bt = BuffType.new("fatigue_bt", FATIGUE_DURATION, 0, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, -MOD_ATTACKSPEED, MOD_ATTACKSPEED_ADD)
	fatigue_bt.set_buff_modifier(mod)
	fatigue_bt.set_buff_icon("res://resources/icons/generic_icons/animal_skull.tres")
	fatigue_bt.set_buff_tooltip(tr("NU0J"))

	axe_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 900, self)
	axe_pt.set_event_on_interpolation_finished(on_projectile_hit)


func on_attack(event: Event):
	var creep: Unit = event.get_target()
	var level: int = tower.get_level()

	if !tower.calc_chance(ON_ATTACK_CHANCE):
		return

	CombatLog.log_ability(tower, creep, "Ice Smashing Axe")

	var projectile: Projectile = Projectile.create_linear_interpolation_from_unit_to_unit(axe_pt, tower, 1, 1, tower, creep, 0.2, true)
	var dmg_per_purge: float = _stats.smashing_axe_dmg + _stats.smashing_axe_dmg_add * level
	projectile.user_real = dmg_per_purge
	projectile.set_projectile_scale(1.5)
	fatigue_bt.apply(tower, tower, tower.get_level())


func on_damage(event: Event):
	var creep: Creep = event.get_target()
	var level: int = tower.get_level()
	var base_speed: float = creep.get_base_movespeed()
	var current_speed: float = creep.get_current_movespeed()

	if current_speed < base_speed:
		var slow_percent: float = (base_speed - current_speed) / base_speed * 100
		var dmg_ratio: float = max(0.0, slow_percent * (_stats.coated_axes_dmg + _stats.coated_axes_dmg_add * level))
		var bonus_damage: float = event.damage * dmg_ratio
		event.damage += bonus_damage
		tower.get_player().display_small_floating_text("+" + str(int(bonus_damage)), creep, Color8(100, 100, 255), 0)


func on_projectile_hit(projectile: Projectile, creep: Unit):
	if creep == null:
		return

	var purged_count: int = 0
	var damage: float = tower.get_current_attack_damage_with_bonus()

	var stun_duration: float
	if creep.get_size() < CreepSize.enm.BOSS:
		stun_duration = STUN_DURATION
	else:
		stun_duration = STUN_DURATION_FOR_BOSSES

	while true:
		var purge_friendly_success: bool = creep.purge_buff(true)
		var purge_unfriendly_success: bool = creep.purge_buff(false)

		if !purge_friendly_success && !purge_unfriendly_success:
			break

		purged_count += 1 

	if purged_count != 0:
		var dmg_per_purge: float = projectile.user_real
		var damage_from_purges: float = damage * (dmg_per_purge * purged_count)
		tower.do_attack_damage(creep, damage_from_purges, tower.calc_attack_multicrit_no_bonus())

		if purged_count > PURGE_COUNT_FOR_STUN:
			stun_bt.apply_only_timed(tower, creep, stun_duration)

	Effect.create_simple_at_unit_attached("res://src/effects/frost_armor_damage.tscn", creep)
