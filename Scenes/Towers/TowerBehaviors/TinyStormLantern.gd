extends TowerBehavior


# NOTE: added more checks for validity of units


var ball: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {num_shots = 2},
		2: {num_shots = 3},
		3: {num_shots = 4},
		4: {num_shots = 5},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var num_shots: String = Utils.format_float(_stats.num_shots, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Burst Lightning"
	ability.icon = "res://Resources/Icons/electricity/thunderstorm.tres"
	ability.description_short = "Has a chance on attack to fire extra projectiles at random creeps around the main target. Projectiles deal attack damage.\n"
	ability.description_full = "Has a 20%% chance on attack to fire %s extra projectiles at random creeps in 300 range around the main target. Each extra projectile deals the same amount of attack damage as a normal attack.\n" % num_shots \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% chance\n" \
	+ "+1 extra projectile at levels 15 and 25\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)



func hit(_p: Projectile, creep: Unit):
	if creep == null:
		return

	tower.do_attack_damage(creep, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit(0, 0, 0))


func new_attack(num_shots: int, creep: Creep):
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), creep, 300)
	var next: Creep

	await Utils.create_timer(0.2, self).timeout

	next = it.next_random()

	while true:
		if next == null:
			if !Utils.unit_is_valid(tower) || !Utils.unit_is_valid(creep):
				return

			Projectile.create_from_unit_to_unit(ball, tower, 1, 0, tower, creep, true, false, false).set_projectile_scale(0.5)
		else:
			Projectile.create_from_unit_to_unit(ball, tower, 1, 0, tower, next, true, false, false).set_projectile_scale(0.5)
			next = it.next_random()

		num_shots = num_shots - 1

		if num_shots == 0:
			return

		await Utils.create_timer(0.2, self).timeout


func tower_init():
	ball = ProjectileType.create("PurgeBuffTarget.mdl", 4, 1000, self)
	ball.enable_homing(hit, 0)


func on_attack(event: Event):
	if !tower.calc_chance(0.2 + 0.01 * tower.get_level()):
		return

	var creep: Creep = event.get_target()
	var num_shots: int = _stats.num_shots
	var twr_level: int = tower.get_level()

	CombatLog.log_ability(tower, creep, "Burst Lightning")

	if twr_level == 25:
		num_shots = num_shots + 2
	elif twr_level >= 15:
		num_shots = num_shots + 1

	new_attack(num_shots, creep)
