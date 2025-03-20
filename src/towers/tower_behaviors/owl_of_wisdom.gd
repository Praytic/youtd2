extends TowerBehavior


var missile_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_ratio_for_immune = 0.10, dmg_ratio_for_immune_add = 0.004, periodic_event_period = 5.0, energyball_chance = 0.25, energyball_radius_add = 1, energyball_dmg_base = 4500, energyball_dmg_exp_scale = 2.25},
		2: {dmg_ratio_for_immune = 0.15, dmg_ratio_for_immune_add = 0.006, periodic_event_period = 4.0, energyball_chance = 0.30, energyball_radius_add = 2, energyball_dmg_base = 6500, energyball_dmg_exp_scale = 3.25},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_periodic_event(periodic, _stats.periodic_event_period)


func tower_init():
	missile_pt = ProjectileType.create("res://src/projectiles/projectile_visuals/energy_ball.tscn", 5.0, 950.0, self)
	missile_pt.enable_homing(missile_pt_on_hit, 0)


func on_attack(event: Event):
	var target: Creep = event.get_target()
	var chance: float = 0.25 + 0.004 * tower.get_level()

	if !tower.calc_chance(chance):
		return

	CombatLog.log_ability(tower, target, "Energyball")

	tomy_energyball_start(target)


func on_create(_preceding: Tower):
	tower.user_int = 1


func periodic(_event: Event):
	var chance: float = 0.10 + 0.002 * tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 900)

	while true:
		var target: Creep = it.next()

		if target == null:
			break

		if tower.calc_chance(chance):
			CombatLog.log_ability(tower, target, "Energy Detection")
			tomy_energyball_start(target)


func tomy_energyball_start(target: Creep):
	Projectile.create_from_unit_to_unit(missile_pt, tower, 0, 0, tower, target, true, false, false)


func missile_pt_on_hit(projectile: Projectile, target: Unit):
	if target == null:
		return

	var aoe_range: float = 100 + 1 * tower.get_level()

	var wave_level: int = tower.get_player().get_team().get_level()
	var damage_bonus_from_exp_max: float = 150.0 * wave_level
	var damage_bonus_from_exp: float = min(_stats.energyball_dmg_exp_scale * tower.get_exp(), damage_bonus_from_exp_max)
	var immune_damage_ratio: float = _stats.dmg_ratio_for_immune + _stats.dmg_ratio_for_immune_add * tower.get_level()
	
	var energyball_damage: float
	if !target.is_immune():
		energyball_damage = _stats.energyball_dmg_base + damage_bonus_from_exp
	else:
		energyball_damage = (_stats.energyball_dmg_base + damage_bonus_from_exp) * immune_damage_ratio * tower.get_prop_spell_damage_dealt()
	
	if !target.is_immune():
		tower.do_spell_damage_aoe_unit(target, aoe_range, energyball_damage, tower.calc_spell_crit_no_bonus(), 0)
	else:
		tower.do_attack_damage_aoe_unit(target, aoe_range, energyball_damage, tower.calc_spell_crit_no_bonus(), 0)

	Effect.create_colored("res://src/effects/wisp_explode.tscn", Vector3(projectile.get_x(), projectile.get_y(), 0.0), 0, 1, Color.BLUE)
