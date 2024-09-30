extends TowerBehavior


# NOTE: fixed bug in original script. If robot ability
# failed to find a target then it would do an early return
# and stop emitter from happening. It was not actually
# critical because robot ability almost always finds a
# target because there are many towers nearby - fixed it
# anyway.

# NOTE: original script used same ProjectileType for robot
# and emitter. Created separate PT for emitter.


var sapper_pt: ProjectileType
var robot_pt: ProjectileType
var emitter_pt: ProjectileType
var sapper_bt: BuffType
var robot_bt: BuffType
var emitter_bt: BuffType


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var reimbursement: AbilityInfo = AbilityInfo.new()
	reimbursement.name = "Reimbursement"
	reimbursement.icon = "res://resources/icons/mechanical/gold_machine.tres"
	reimbursement.description_short = "Reimburses gold when no ability is used.\n"
	reimbursement.description_full = "Whenever this tower attacks and doesn't trigger any of it's abilities, the player is reimbursed 5 gold.\n"
	list.append(reimbursement)

	var field: AbilityInfo = AbilityInfo.new()
	field.name = "Probability Field Emitter"
	field.icon = "res://resources/icons/dioramas/fountain.tres"
	field.description_short = "Whenever this tower attacks, it has a chance to launch a [color=GOLD]Probability Field Emitter[/color] at a random tower, increasing trigger chances.\n"
	field.description_full = "Whenever this tower attacks, it has a 20% chance to launch a [color=GOLD]Probability Field Emitter[/color] at a random tower within 500 range, increasing trigger chances by [color=GOLD]30%-60%[/color] for 5 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% chance\n" \
	+ "+0.6% trigger chances\n"
	field.radius = 500
	field.target_type = TargetType.new(TargetType.TOWERS)
	list.append(field)

	var clockwork: AbilityInfo = AbilityInfo.new()
	clockwork.name = "Clockwork Engineer"
	clockwork.icon = "res://resources/icons/mechanical/mech_badge.tres"
	clockwork.description_short = "Whenever this tower attacks, it has a chance to launch a [color=GOLD]Clockwork Engineer[/color] at a random tower, increasing attack speed and damage.\n"
	clockwork.description_full = "Whenever this tower attacks, it has a 20% chance to launch a [color=GOLD]Clockwork Engineer[/color] at a random tower within 500 range, increasing attack speed and attack damage by [color=GOLD]10%-40%[/color] for 5 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% chance\n" \
	+ "+0.6% attack speed and damage\n"
	clockwork.radius = 500
	clockwork.target_type = TargetType.new(TargetType.TOWERS)
	list.append(clockwork)

	var sapper: AbilityInfo = AbilityInfo.new()
	sapper.name = "Goblin Sapper"
	sapper.icon = "res://resources/icons/faces/mech_zombie.tres"
	sapper.description_short = "Whenever this tower attacks, it has chance to launch a [color=GOLD]Goblin Sapper[/color] at the main target, dealing AoE spell damage and slowing creeps in an AoE.\n"
	sapper.description_full = "Whenever this tower attacks, it has a 20% chance to launch a [color=GOLD]Goblin Sapper[/color] at the main target. On contact [color=GOLD]Goblin Sapper[/color] deals [color=GOLD]1350-7650[/color] spell damage to the main target and all creeps within 250 range. Also slows all affected creeps by [color=GOLD]25%-45%[/color] for 3 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% chance\n" \
	+ "+180 spell damage\n" \
	+ "+0.6% slow\n"
	list.append(sapper)

	return list


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
	cedi_goblin_sapper_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	sapper_bt.set_buff_modifier(cedi_goblin_sapper_mod)
	sapper_bt.set_buff_icon("res://resources/icons/generic_icons/barefoot.tres")
	sapper_bt.set_buff_tooltip("Sapper Burn\nReduces movement speed.")

	robot_bt = BuffType.new("robot_bt", 5, 0, true, self)
	var cedi_goblin_robot_mod: Modifier = Modifier.new()
	cedi_goblin_robot_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.001)
	cedi_goblin_robot_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.001)
	robot_bt.set_buff_modifier(cedi_goblin_robot_mod)
	robot_bt.set_buff_icon("res://resources/icons/generic_icons/cog.tres")
	robot_bt.set_special_effect("res://src/effects/holy_bolt.tscn", 200, 5.0)
	robot_bt.set_buff_tooltip("Clockwork Engineer\nIncreases attack speed and attack damage.")

	emitter_bt = BuffType.new("emitter_bt", 5, 0, true, self)
	var cedi_goblin_emitter_mod: Modifier = Modifier.new()
	cedi_goblin_emitter_mod.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.0, 0.001)
	emitter_bt.set_buff_modifier(cedi_goblin_emitter_mod)
	emitter_bt.set_buff_icon("res://resources/icons/generic_icons/azul_flake.tres")
	emitter_bt.set_special_effect("res://src/effects/frost_bolt_missile.tscn", 200, 5.0)
	emitter_bt.set_buff_tooltip("Probability Field Emitter\nIncreases trigger chances.")


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

	var floating_text: String = "%d%% slow" % (slow_buff_level / 10) 
	tower.get_player().display_small_floating_text(floating_text, target, Color8(100, 100, 255), 40)

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

	var floating_text: String = "%d%% AS and DMG" % (buff_level / 10) 
	tower.get_player().display_small_floating_text(floating_text, target, Color8(100, 255, 100), 40)


func emitter_pt_on_hit(_projectile: Projectile, target: Unit):
	if target == null:
		return

	var level: int = tower.get_level()
	var buff_level: int = Globals.synced_rng.randi_range(300, 600) + 6 * level

	if tower == null:
		return

	emitter_bt.apply(tower, target, buff_level)

	var floating_text: String = "%d%% Trigger Chance" % (buff_level / 10) 
	tower.get_player().display_small_floating_text(floating_text, target, Color8(100, 255, 100), 40)
