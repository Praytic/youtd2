extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed bug which happened if
# robot ability failed to find a target. It would do an
# early return and stop emitter from happening. Note that
# this bug is not critical because robot ability almost
# always finds a target because there are many towers
# nearby.

# NOTE: original script used same ProjectileType for robot
# and emitter. Created separate PT for emitter.


var sapper_pt: ProjectileType
var robot_pt: ProjectileType
var emitter_pt: ProjectileType
var sapper_bt: BuffType
var robot_bt: BuffType
var emitter_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	sapper_pt = ProjectileType.create("path_to_projectile_sprite", 20, 700, self)
	sapper_pt.enable_homing(sapper_pt_on_hit, 0)

	robot_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 200, self)
	robot_pt.set_event_on_interpolation_finished(robot_pt_on_hit)

	emitter_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 200, self)
	emitter_pt.set_event_on_interpolation_finished(emitter_pt_on_hit)

	sapper_bt = BuffType.new("sapper_bt", 3, 0, false, self)
	var cedi_goblin_sapper_mod: Modifier = Modifier.new()
	cedi_goblin_sapper_mod.add_modification(ModificationType.enm.MOD_MOVESPEED, 0.0, -0.001)
	sapper_bt.set_buff_modifier(cedi_goblin_sapper_mod)
	sapper_bt.set_buff_icon("res://resources/icons/generic_icons/barefoot.tres")
	sapper_bt.set_buff_tooltip(tr("SBOV"))

	robot_bt = BuffType.new("robot_bt", 5, 0, true, self)
	var cedi_goblin_robot_mod: Modifier = Modifier.new()
	cedi_goblin_robot_mod.add_modification(ModificationType.enm.MOD_DAMAGE_ADD_PERC, 0.0, 0.001)
	cedi_goblin_robot_mod.add_modification(ModificationType.enm.MOD_ATTACKSPEED, 0.0, 0.001)
	robot_bt.set_buff_modifier(cedi_goblin_robot_mod)
	robot_bt.set_buff_icon("res://resources/icons/generic_icons/cog.tres")
	robot_bt.set_special_effect("res://src/effects/holy_bolt.tscn", 100, 1.0)
	robot_bt.set_buff_tooltip(tr("ZENW"))

	emitter_bt = BuffType.new("emitter_bt", 5, 0, true, self)
	var cedi_goblin_emitter_mod: Modifier = Modifier.new()
	cedi_goblin_emitter_mod.add_modification(ModificationType.enm.MOD_TRIGGER_CHANCES, 0.0, 0.001)
	emitter_bt.set_buff_modifier(cedi_goblin_emitter_mod)
	emitter_bt.set_buff_icon("res://resources/icons/generic_icons/azul_flake.tres")
	emitter_bt.set_special_effect("res://src/effects/frost_bolt_missile.tscn", 100, 1.0)
	emitter_bt.set_buff_tooltip(tr("KB5O"))


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
#	NOTE: it's the same chance value for all 3 abilities
	var chance: float = 0.20 + 0.004 * level
	var do_sapper: bool = tower.calc_chance(chance)
	var do_robot: bool = tower.calc_chance(chance)
	var do_emitter: bool = tower.calc_chance(chance)

	if do_sapper:
		CombatLog.log_ability(tower, target, "Goblin Sapper")
		Projectile.create_from_unit_to_unit(sapper_pt, tower, 1.0, 1.0, tower, target, true, false, false)

	if do_robot:
		CombatLog.log_ability(tower, target, "Clockwork Engineer")
		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)
		var next: Unit = it.next_random()

#		Don't target self
		if next == tower:
			next = it.next_random()

		if next != null:
			Projectile.create_linear_interpolation_from_unit_to_unit(robot_pt, tower, 1.0, 1.0, tower, next, 0.35, true)

	if do_emitter:
		CombatLog.log_ability(tower, null, "Probability Field Emitter")
		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)
		var next: Unit = it.next_random()

#		Don't target self
		if next == tower:
			next = it.next_random()

		if next != null:
			var projectile: Projectile = Projectile.create_linear_interpolation_from_unit_to_unit(emitter_pt, tower, 1.0, 1.0, tower, next, 0.33, true)
			var emitter_buff_level: int = Globals.synced_rng.randi_range(300, 600) + 6 * level
			projectile.user_int = emitter_buff_level

	var used_ability: bool = do_sapper || do_robot || do_emitter
	if !used_ability:
		CombatLog.log_ability(tower, null, "Reimbursement")
		tower.get_player().give_gold(5, tower, true, true)


func sapper_pt_on_hit(projectile: Projectile, target: Unit):
	if target == null:
		return

	var level: int = tower.get_level()
	var sapper_damage: float = Globals.synced_rng.randi_range(1350, 7650) + 180 * level
	var slow_buff_level: int = Globals.synced_rng.randi_range(250, 450) + 6 * level

	if tower == null:
		return

	var slow_text: String = tr("EMCY") % (slow_buff_level / 10) 
	tower.get_player().display_small_floating_text(slow_text, target, Color8(100, 100, 255), 40)

	Effect.add_special_effect("res://src/effects/frag_boom_spawn.tscn", Vector2(projectile.get_x(), projectile.get_y()))

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 250)
	
	while true:
		var next: Unit = it.next()

		if next == null:
			break

		tower.do_spell_damage(next, sapper_damage, tower.calc_spell_crit_no_bonus())
		sapper_bt.apply(tower, next, slow_buff_level)


func robot_pt_on_hit(_projectile: Projectile, target: Unit):
	if target == null:
		return

	var level: int = tower.get_level()
	var buff_level: int = Globals.synced_rng.randi_range(100, 400) + 6 * level

	if tower == null:
		return

	robot_bt.apply(tower, target, buff_level)

	var attackspeed_and_dmg_text: String = tr("F7DM") % (buff_level / 10) 
	tower.get_player().display_small_floating_text(attackspeed_and_dmg_text, target, Color8(100, 255, 100), 40)


func emitter_pt_on_hit(_projectile: Projectile, target: Unit):
	if target == null:
		return

	var level: int = tower.get_level()
	var buff_level: int = Globals.synced_rng.randi_range(300, 600) + 6 * level

	if tower == null:
		return

	emitter_bt.apply(tower, target, buff_level)

	var trigger_chances_text: String = tr("R735") % (buff_level / 10) 
	tower.get_player().display_small_floating_text(trigger_chances_text, target, Color8(100, 255, 100), 40)
