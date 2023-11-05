extends Tower


# NOTE: changed how gatling fire is enabled. Using a bool
# flag instead of enabling/disabling periodic event.



var ball_pt: ProjectileType
var boekie_gatling_bt: BuffType

var gatling_fire_enabled: bool = false
var gatling_fire_target: Unit = null
var gatling_fire_count: int = 0
var gatling_fire_dmg_ratio: float = 0.0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Rapid Gun Fire[/color]\n"
	text += "Has a 65% chance on attack to shoot an extra projectile. Every extra projectile can be followed up by another projectile, but the chance is reduced by 6% each time. Every extra projectile deals the same amount of damage as a normal attack and has a 10% chance to explode, dealing that damage in 200 AoE around the target. Maximum of 10 extra projectiles per attack.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% chance\n"
	text += "+0.3% chance to explode\n"
	text += " \n"

	text += "[color=GOLD]Sentry[/color]\n"
	text += "This tower gains 15% attackdamage whenever a creep comes within 800 range of it. Lasts 3 seconds and stacks up to 20 times.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.5% damage\n"
	text += "+0.05 seconds duration\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Rapid Gun Fire[/color]\n"
	text += "Has a chance on attack to shoot an extra projectile.\n"
	text += " \n"

	text += "[color=GOLD]Sentry[/color]\n"
	text += "This tower gains attack damage whenever a creep comes within range.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_periodic_event(periodic, 0.1)
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 800, TargetType.new(TargetType.CREEPS))


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.10, 0.005)


func tower_init():
	ball_pt = ProjectileType.create("BoatMissile.mdl", 4, 1000, self)
	ball_pt.enable_homing(ball_pt_on_hit, 0)

	boekie_gatling_bt = BuffType.new("boekie_gatling_bt", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.005)
	boekie_gatling_bt.set_buff_modifier(mod)
	boekie_gatling_bt.set_buff_icon("@@0@@")
	boekie_gatling_bt.set_buff_tooltip("Sentry\nThis tower acts as a Sentry; it deals bonus attack damage.")


func on_attack(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var projectile_count_max: int = int(tower.get_current_attack_speed() / 0.1)
	var dmg_ratio: float = 1.0

	var rapid_gun_fire_chance: float = 0.65 + 0.004 * tower.get_level()

	if !tower.calc_chance(rapid_gun_fire_chance):
		return

#	Increment amount of extra attacks until the chance isn't
#	met or max is reached.
	var projectile_count: int = 1
	while true:
		var extra_projectile_chance: float = 0.65 + 0.004 * tower.get_level() - 0.06 * projectile_count
		var chance_success: bool = tower.calc_chance(extra_projectile_chance)

		if !chance_success || projectile_count > 10:
			break

		projectile_count += 1

#	If tower cannot release as many projectiles as required,
#	scale the dmg instead!
	if projectile_count > projectile_count_max:
		dmg_ratio = float(projectile_count) / float(projectile_count_max)
		projectile_count = projectile_count_max

#	Sets the target to shoot balls at and makes the periodic
#	period smaller to get the rapid attack
	gatling_fire_enabled = true
	gatling_fire_target = target
	gatling_fire_count = projectile_count
	gatling_fire_dmg_ratio = dmg_ratio


func on_unit_in_range(_event: Event):
	var tower: Tower = self
	var tower_level: int = tower.get_level()
	var buff_level: int = 1
	var buff: Buff = tower.get_buff_of_type(boekie_gatling_bt)

	if buff != null:
		buff_level = min(buff.user_int + 1, 20)

	var buff_duration: float = 3.0 + 0.05 * tower_level

	buff = boekie_gatling_bt.apply_custom_timed(tower, tower, buff_level * (30 + tower_level), buff_duration)
	buff.user_int = buff_level


func periodic(_event: Event):
	var tower: Tower = self

	if !gatling_fire_enabled:
		return

	if !Utils.unit_is_valid(gatling_fire_target):
		gatling_fire_enabled = false

		return

	if gatling_fire_count == 0:
		gatling_fire_enabled = false
		
		return

	var gatling_shot: Projectile = Projectile.create_from_unit_to_unit(ball_pt, tower, 1.0, 0.0, tower, gatling_fire_target, true, false, false)
	gatling_shot.user_real = gatling_fire_dmg_ratio

	gatling_fire_count -= 1


func ball_pt_on_hit(projectile: Projectile, creep: Unit):
	var tower: Tower = projectile.get_caster()
	var explode_chance: float = 0.10 + 0.003 * tower.get_level()
	var exploded: bool = tower.calc_chance(explode_chance)
	var damage: float = projectile.user_real * tower.get_current_attack_damage_with_bonus()

	if exploded:
		var effect: int = Effect.create_scaled("FireLordDeathExplode.mdl", projectile.get_x(), projectile.get_y(), 30.0, 0, 1.6)
		Effect.set_lifetime(effect, 1.0)

		tower.do_attack_damage_aoe_unit(creep, 200, damage, tower.calc_attack_multicrit_no_bonus(), 0.0)
	else:
		tower.do_attack_damage(creep, damage, tower.calc_attack_multicrit_no_bonus())
