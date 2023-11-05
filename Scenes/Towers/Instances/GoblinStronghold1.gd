extends Tower


# NOTE: fixed bug in original script. If robot ability
# failed to find a target then it would do an early return
# and stop emitter from happening. It was not actually
# critical because robot ability almost always finds a
# target because there are many towers nearby - fixed it
# anyway.

# NOTE: original script used same ProjectileType for robot
# and emitter. Created separate PT for emitter.


var cedi_goblin_sapper_pt: ProjectileType
var cedi_goblin_robot_pt: ProjectileType
var cedi_goblin_emitter_pt: ProjectileType
var cedi_goblin_sapper_bt: BuffType
var cedi_goblin_robot_bt: BuffType
var cedi_goblin_emitter_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Reimbursement[/color]\n"
	text += "Whenever this tower attacks and doesn't trigger any of it's abilities, the player is reimbursed 5 gold.\n"
	text += " \n"

	text += "[color=GOLD]Probability Field Emitter[/color]\n"
	text += "Whenever this tower attacks it has a 20% chance to launch a probability field emitter at a random tower within 500 range, increasing trigger chances by 30% - 60% for 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% chance\n"
	text += "+0.6% trigger chances\n"
	text += " \n"

	text += "[color=GOLD]Clockwork Engineer[/color]\n"
	text += "Whenever this tower attacks it has a 20% chance to launch a clockwork engineer at a random tower within 500 range, increasing attack speed and damage by 10% - 40% for 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% chance\n"
	text += "+0.6% attack speed and damage\n"
	text += " \n"

	text += "[color=GOLD]Goblin Sapper[/color]\n"
	text += "Whenever this tower attacks it has a 20% chance to launch a sapper team at the attacked creep. On contact the sappers deal 1350 - 7650 spell damage to the target and all creeps within 250 range. Also slows all affected creeps by 25% - 45% for 3 seconds."
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% chance\n"
	text += "+180 spell damage\n"
	text += "+0.6% slow\n"
	text += " \n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Reimbursement[/color]\n"
	text += "Reimburses gold when no ability is used.\n"
	text += " \n"

	text += "[color=GOLD]Probability Field Emitter[/color]\n"
	text += "Chance to launch a probability field emitter at a random tower, increasing trigger chances.\n"
	text += " \n"

	text += "[color=GOLD]Clockwork Engineer[/color]\n"
	text += "Chance to launch a clockwork engineer at a random tower, increasing attack speed and damage.\n"
	text += " \n"

	text += "[color=GOLD]Goblin Sapper[/color]\n"
	text += "Chance to launch a sapper team at the attacked creep."
	text += " \n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	cedi_goblin_sapper_pt = ProjectileType.create("GoblinSapper.mdl", 20, 700, self)
	cedi_goblin_sapper_pt.enable_homing(cedi_goblin_sapper_pt_on_hit, 0)

	cedi_goblin_robot_pt = ProjectileType.create_interpolate("HeroTinkerRobot.mdl", 200, self)
	cedi_goblin_robot_pt.set_event_on_interpolation_finished(cedi_goblin_robot_pt_on_hit)

	cedi_goblin_emitter_pt = ProjectileType.create_interpolate("GoblinLandMine.mdl", 200, self)
	cedi_goblin_emitter_pt.set_event_on_interpolation_finished(cedi_goblin_emitter_pt_on_hit)

	cedi_goblin_sapper_bt = BuffType.new("cedi_goblin_sapper_bt", 3, 0, false, self)
	var cedi_goblin_sapper_mod: Modifier = Modifier.new()
	cedi_goblin_sapper_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	cedi_goblin_sapper_bt.set_buff_modifier(cedi_goblin_sapper_mod)
	cedi_goblin_sapper_bt.set_buff_icon("@@2@@")
	cedi_goblin_sapper_bt.set_buff_tooltip("Sapper Burn\nThis creep was hit by a Goblin Sapper; it has reduced movement speed.")

	cedi_goblin_robot_bt = BuffType.new("cedi_goblin_robot_bt", 5, 0, true, self)
	var cedi_goblin_robot_mod: Modifier = Modifier.new()
	cedi_goblin_robot_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.001)
	cedi_goblin_robot_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.001)
	cedi_goblin_robot_bt.set_buff_modifier(cedi_goblin_robot_mod)
	cedi_goblin_robot_bt.set_buff_icon("@@3@@")
	# TODO: BuffType.set_special_effect() is not implemented yet
	# cedi_goblin_robot_bt.set_special_effect("HeroTinkerRobot.mdl", 120, 0.7)
	cedi_goblin_robot_bt.set_buff_tooltip("Clockwork Engineer\nThis tower is receiving assistance from Clockwork Engineer; it has increased attack speed and damage.")

	cedi_goblin_emitter_bt = BuffType.new("cedi_goblin_emitter_bt", 5, 0, true, self)
	var cedi_goblin_emitter_mod: Modifier = Modifier.new()
	cedi_goblin_emitter_mod.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.0, 0.001)
	cedi_goblin_emitter_bt.set_buff_modifier(cedi_goblin_emitter_mod)
	cedi_goblin_emitter_bt.set_buff_icon("@@4@@")
	# TODO: BuffType.set_special_effect() is not implemented yet
	# cedi_goblin_emitter_bt.set_special_effect("GoblinLandMine.mdl", 120, 1.0)
	cedi_goblin_emitter_bt.set_buff_tooltip("Probability Field Emitter\nThis tower is affected by a Probability Field Emitter; it has increased trigger chances.")


func on_attack(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
#	NOTE: it's the same chance value for all 3 abilities
	var chance: float = 0.20 + 0.004 * level
	var do_sapper: bool = tower.calc_chance(chance)
	var do_robot: bool = tower.calc_chance(chance)
	var do_emitter: bool = tower.calc_chance(chance)

	if do_sapper:
		Projectile.create_from_unit_to_unit(cedi_goblin_sapper_pt, tower, 1.0, 1.0, tower, target, true, false, false)

	if do_robot:
		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)
		var next: Unit = it.next_random()

#		Don't target self
		if next == tower:
			next = it.next_random()

		if next != null:
			Projectile.create_linear_interpolation_from_unit_to_unit(cedi_goblin_robot_pt, tower, 1.0, 1.0, tower, next, 0.35, true)

	if do_emitter:
		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)
		var next: Unit = it.next_random()

#		Don't target self
		if next == tower:
			next = it.next_random()

		if next != null:
			var projectile: Projectile = Projectile.create_linear_interpolation_from_unit_to_unit(cedi_goblin_emitter_pt, tower, 1.0, 1.0, tower, next, 0.33, true)
			var emitter_buff_level: int = randi_range(300, 600) + 6 * level
			projectile.user_int = emitter_buff_level

	var used_ability: bool = do_sapper || do_robot || do_emitter
	if !used_ability:
		tower.get_player().give_gold(5, tower, true, true)


func cedi_goblin_sapper_pt_on_hit(projectile: Projectile, target: Unit):
	var tower: Tower = projectile.get_caster()
	var level: int = tower.get_level()
	var sapper_damage: float = randi_range(1350, 7650) + 180 * level
	var slow_buff_level: int = randi_range(250, 450) + 6 * level

	if tower == null:
		return

	var floating_text: String = "%d%% slow" % (slow_buff_level / 10) 
	tower.get_player().display_small_floating_text(floating_text, target, 100, 100, 255, 40)

	var effect: int = Effect.add_special_effect("NeutralBuildingExplosion.mdl", projectile.get_x(), projectile.get_y())
	Effect.destroy_effect_after_its_over(effect)

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 250)
	
	while true:
		var next: Unit = it.next()

		if next == null:
			break

		tower.do_spell_damage(next, sapper_damage, tower.calc_spell_crit_no_bonus())
		cedi_goblin_sapper_bt.apply(tower, next, slow_buff_level)


func cedi_goblin_robot_pt_on_hit(projectile: Projectile, target: Unit):
	var tower: Tower = projectile.get_caster()
	var level: int = tower.get_level()
	var buff_level: int = randi_range(100, 400) + 6 * level

	if tower == null:
		return

	cedi_goblin_robot_bt.apply(tower, target, buff_level)

	var floating_text: String = "%d%% AS and DMG" % (buff_level / 10) 
	tower.get_player().display_small_floating_text(floating_text, target, 100, 255, 100, 40)


func cedi_goblin_emitter_pt_on_hit(projectile: Projectile, target: Unit):
	var tower: Tower = projectile.get_caster()
	var level: int = tower.get_level()
	var buff_level: int = randi_range(300, 600) + 6 * level

	if tower == null:
		return

	cedi_goblin_emitter_bt.apply(tower, target, buff_level)

	var floating_text: String = "%d%% Trigger Chance" % (buff_level / 10) 
	tower.get_player().display_small_floating_text(floating_text, target, 100, 255, 100, 40)
