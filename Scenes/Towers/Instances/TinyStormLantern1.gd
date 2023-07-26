extends Tower


# NOTE: added more checks for validity of units


var ball: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {num_shots = 2},
		2: {num_shots = 3},
		3: {num_shots = 4},
		4: {num_shots = 5},
	}


func get_extra_tooltip_text() -> String:
	var num_shots: String = str(_stats.num_shots)

	var text: String = ""

	text += "[color=GOLD]Burst Lightning[/color]\n"
	text += "Has a 20%% chance on attack to fire %s extra projectiles at random creeps in 300 range around the main target. Each extra projectile deals the same amount of damage as a normal attack.\n" % num_shots
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1%% chance\n"
	text += "+1 extra projectile at levels 15 and 25\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)



func hit(p: Projectile, creep: Unit):
	var tower: Tower = p.get_caster()
	tower.do_attack_damage(creep, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit(0, 0, 0))


func new_attack(tower: Tower, num_shots: int, creep: Creep):
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), creep, 300)
	var next: Creep

	await get_tree().create_timer(0.2).timeout

	next = it.next_random()

	while true:
		if next == null:
			if !Utils.unit_is_valid(tower) || !Utils.unit_is_valid(creep):
				return

			Projectile.create_from_unit_to_unit(ball, tower, 1, 0, tower, creep, true, false, false).setScale(0.5)
		else:
			Projectile.create_from_unit_to_unit(ball, tower, 1, 0, tower, next, true, false, false).setScale(0.5)
			next = it.next_random()

		num_shots = num_shots - 1

		if num_shots == 0:
			return

		await get_tree().create_timer(0.2).timeout

	if next != null:
		it.destroy()


func tower_init():
	ball = ProjectileType.create("PurgeBuffTarget.mdl", 4, 1000)
	ball.enable_homing(hit, 0)


func on_attack(event: Event):
	var tower: Tower = self

	if !tower.calc_chance(0.2 + 0.01 * tower.get_level()):
		return

	var creep: Creep = event.get_target()
	var num_shots: int = _stats.num_shots
	var twr_level: int = tower.get_level()

	if twr_level == 25:
		num_shots = num_shots + 2
	elif twr_level >= 15:
		num_shots = num_shots + 1

	new_attack(tower, num_shots, creep)
