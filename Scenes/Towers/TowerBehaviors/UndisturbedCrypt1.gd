extends TowerBehavior


# NOTE: reworked JASS script. Instead of storing buff
# level in userInt I calculate it when it's needed. This
# makes the incDmg function unnecessary. Changed periodic
# function to attach to triggers buff type in
# load_triggers() instead of to EventTypeList in
# tower_init().


var ball_pt: ProjectileType
var meat_pt: ProjectileType
var corpse_explosion_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {critical_mass_chance = 0.30, buff_level = 50, buff_level_add = 2},
		2: {critical_mass_chance = 0.33, buff_level = 80, buff_level_add = 3},
		3: {critical_mass_chance = 0.36, buff_level = 130, buff_level_add = 4},
		4: {critical_mass_chance = 0.39, buff_level = 200, buff_level_add = 6},
	}


func get_ability_description() -> String:
	var debuff_effect: String = Utils.format_percent(_stats.buff_level * 0.001, 2)
	var debuff_effect_add: String = Utils.format_percent(_stats.buff_level_add * 0.001, 2)
	var critical_mass_chance: String = Utils.format_percent(_stats.critical_mass_chance, 2)

	var text: String = ""

	text += "[color=GOLD]Corpse Explosion[/color]\n"
	text += "Explodes a corpse within 1000 range of the tower, causing enemies in 500 range of the corpse to take %s more damage from darkness towers and move %s slower for 8 seconds. 5 second cooldown. Doesn't affect Air.\n" % [debuff_effect, debuff_effect]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s slow and damage taken\n" % debuff_effect_add
	text += "+0.25 seconds duration\n"
	text += " \n"
	text += "[color=GOLD]Critical Mass[/color]\n"
	text += "Has a 30%% chance on attack to shoot an extra projectile. For each projectile after the initial one, there is a %s chance to shoot an extra projectile. There is a maximum of 14 projectiles fired per attack.\n" % critical_mass_chance
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.3% initial chance\n"
	text += "+0.6% extra chance\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Corpse Explosion[/color]\n"
	text += "Occasionally explodes nearby corpses and deals AoE damage.\n"
	text += " \n"
	text += "[color=GOLD]Critical Mass[/color]\n"
	text += "Has a chance on attack to shoot multiple projectiles.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_periodic_event(periodic, 5)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Corpse Explosion", 1000, TargetType.new(TargetType.CREEPS))]


func burst_fire(chance: float, target: Creep):
	var num_shots: int = 0

	while true:
		var p: Projectile = Projectile.create_from_unit_to_unit(ball_pt, tower, 1.0, 1.0, tower, target, true, false, false)
		p.set_projectile_scale(0.4)
		num_shots = num_shots + 1

		if !tower.calc_chance(chance) || num_shots >= 14 || !Utils.unit_is_valid(target):
			break

	CombatLog.log_ability(tower, null, "Critical Mass %d" % num_shots)


func ball_pt_on_hit(_p: Projectile, creep: Unit):
	if creep == null:
		return

	tower.do_attack_damage(creep, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit(0, 0, 0))


func tower_init():
	ball_pt = ProjectileType.create("AnnihilationMissile.mdl", 5, 500, self)
	ball_pt.enable_homing(ball_pt_on_hit, 0)

	meat_pt = ProjectileType.create_interpolate("T_MeatwagonMissile.mdl", 400, self)

	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	m.add_modification(Modification.Type.MOD_DMG_FROM_DARKNESS, 0.0, 0.001)

	corpse_explosion_bt = BuffType.new("corpse_explosion_bt", 8, 0.25, false, self)
	corpse_explosion_bt.set_buff_icon("res://Resources/Textures/GenericIcons/alien_skull.tres")
	corpse_explosion_bt.set_buff_modifier(m)
	corpse_explosion_bt.set_buff_tooltip("Corpse Explosion\nIncreases damage taken from Darkness towers and reduces movement speed.")


func on_attack(event: Event):
	if !tower.calc_chance(0.3 + 0.003 * tower.get_level()):
		return

	var chance: float = _stats.critical_mass_chance + 0.006 * tower.get_level()
	burst_fire(chance, event.get_target())


# NOTE: this f-n is named "fire()" in JASS script
func periodic(_event: Event):
	var corpses_in_range: Iterate = Iterate.over_corpses_in_range(tower, Vector2(tower.get_x(), tower.get_y()), 1000)

	var target_corpse: Unit = null

	while true:
		var corpse: Unit = corpses_in_range.next_corpse()
		
		if corpse == null:
			break

		var creeps_in_range: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), Vector2(corpse.get_x(), corpse.get_y()), 500)

		if creeps_in_range.count() > 0:
			target_corpse = corpse

			break

	if target_corpse == null:
		return

	var tx: float = target_corpse.get_x()
	var ty: float = target_corpse.get_y()

	var explode_effect: int = Effect.add_special_effect("OrcLargeDeathExplode.mdl", Vector2(tx, ty))
	Effect.destroy_effect_after_its_over(explode_effect)

	var missile_effect: int = Effect.create_scaled("T_MeatwagonMissile.mdl", Vector3(tx, ty, 0), Globals.synced_rng.randf_range(0, 360), 5)
	Effect.destroy_effect_after_its_over(missile_effect)

	var creeps_in_range: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), Vector2(tx, ty), 500)

	var buff_level: int = _stats.buff_level + _stats.buff_level_add * tower.get_level()

	while true:
		var creep: Unit = creeps_in_range.next()

		if creep == null:
			break

		var projectile: Projectile = Projectile.create_linear_interpolation_from_unit_to_unit(meat_pt, tower, 0, 0, tower, creep, 0, true)
		projectile.set_projectile_scale(0.5)

		corpse_explosion_bt.apply(tower, creep, buff_level)
