extends TowerBehavior

var stun_bt: BuffType
var fatigue_bt: BuffType
var axe_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_special = 0.10, dmg_special_add = 0.002, smashing_axe_dmg = 0.20, smashing_axe_dmg_add = 0.004, coated_axes_dmg = 0.0060, coated_axes_dmg_add = 0.00020},
		2: {dmg_special = 0.15, dmg_special_add = 0.003, smashing_axe_dmg = 0.25, smashing_axe_dmg_add = 0.005, coated_axes_dmg = 0.0065, coated_axes_dmg_add = 0.00025},
		3: {dmg_special = 0.20, dmg_special_add = 0.004, smashing_axe_dmg = 0.30, smashing_axe_dmg_add = 0.006, coated_axes_dmg = 0.0070, coated_axes_dmg_add = 0.00030},
	}

const ON_ATTACK_CHANCE: float = 0.15
const STUN_DURATION: float = 1.5
const STUN_DURATION_FOR_BOSSES: float = 0.75
const MOD_ATTACKSPEED: float = 0.30
const MOD_ATTACKSPEED_ADD: float = 0.004
const FATIGUE_DURATION: float = 3
const PURGE_COUNT_FOR_STUN: float = 5


func get_ability_info_list() -> Array[AbilityInfo]:
	var on_attack_chance: String = Utils.format_percent(ON_ATTACK_CHANCE, 2)
	var smashing_axe_dmg: String = Utils.format_percent(_stats.smashing_axe_dmg, 2)
	var smashing_axe_dmg_add: String = Utils.format_percent(_stats.smashing_axe_dmg_add, 2)
	var purge_count_for_stun: String = Utils.format_float(PURGE_COUNT_FOR_STUN, 2)
	var stun_duration: String = Utils.format_float(STUN_DURATION, 2)
	var stun_duration_for_bosses: String = Utils.format_float(STUN_DURATION_FOR_BOSSES, 2)
	var mod_attack_speed: String = Utils.format_percent(MOD_ATTACKSPEED, 2)
	var mod_attack_speed_add: String = Utils.format_percent(MOD_ATTACKSPEED_ADD, 2)
	var fatigue_duration: String = Utils.format_float(FATIGUE_DURATION, 2)
	var coated_axes_dmg: String = Utils.format_percent(_stats.coated_axes_dmg, 2)
	var coated_axes_dmg_add: String = Utils.format_percent(_stats.coated_axes_dmg_add, 2)
	var elemental_string: String = AttackType.convert_to_colored_string(AttackType.enm.ELEMENTAL)

	var list: Array[AbilityInfo] = []
	
	var ice_smashing_axe: AbilityInfo = AbilityInfo.new()
	ice_smashing_axe.name = "Ice Smashing Axe"
	ice_smashing_axe.icon = "res://resources/icons/weapons_misc/axe_01.tres"
	ice_smashing_axe.description_short = "Whenever the Troll attacks, he has a chance to throw [color=GOLD]Ice Smashing Axe[/color] at the main target. [color=GOLD]Ice Smashing Axe[/color] shatters all the buffs from the creep and deals %s damage.\n" % elemental_string
	ice_smashing_axe.description_full = "Whenever the Troll attacks, he has a %s chance to throw [color=GOLD]Ice Smashing Axe[/color] at the main target. [color=GOLD]Ice Smashing Axe[/color] shatters all the buffs from its target and deals %s of the tower's attack damage as %s damage for each buff purged. If more than %s buffs are removed the target is also stunned for %s seconds (%s on bosses). The axe is so heavy that its wielder's attack speed is slowed by %s for %s seconds after throwing it.\n" % [on_attack_chance, smashing_axe_dmg, elemental_string, purge_count_for_stun, stun_duration, stun_duration_for_bosses, mod_attack_speed, fatigue_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage per buff\n" % smashing_axe_dmg_add \
	+ "-%s attack speed reduction\n" % mod_attack_speed_add
	list.append(ice_smashing_axe)

	var ice_coated_axes: AbilityInfo = AbilityInfo.new()
	ice_coated_axes.name = "Ice Coated Axes"
	ice_coated_axes.icon = "res://resources/icons/weapons_misc/glaive_01.tres"
	ice_coated_axes.description_short = "Whenever the Troll hits a slowed creep, it deals bonus damage.\n"
	ice_coated_axes.description_full = "Whenever the Troll hits a slowed creep, it deals %s bonus damage for every 1%% movement speed the creep is missing.\n" % coated_axes_dmg \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % coated_axes_dmg_add
	list.append(ice_coated_axes)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, _stats.dmg_special, _stats.dmg_special_add)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, _stats.dmg_special, _stats.dmg_special_add)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)
	
	fatigue_bt = BuffType.new("fatigue_bt", FATIGUE_DURATION, 0, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, -MOD_ATTACKSPEED, MOD_ATTACKSPEED_ADD)
	fatigue_bt.set_buff_modifier(mod)
	fatigue_bt.set_buff_icon("res://resources/icons/generic_icons/animal_skull.tres")
	fatigue_bt.set_buff_tooltip("Fatigue\nReduces attack speed.")

	axe_pt = ProjectileType.create_interpolate("RexxarMissile.mdl", 900, self)
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

	SFX.sfx_at_unit("FrostWyrmMissile.mdl", creep)
