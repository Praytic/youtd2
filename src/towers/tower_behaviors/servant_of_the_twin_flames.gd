extends TowerBehavior


# NOTE: original script appears to have a bug. Twin
# Disciplines is supposed to give 1% per stack for tier 1
# and 2% per stack for tier 2. The script adds +1 to buff
# level per stack for both tiers, so both tiers add 1% per
# stack. Fixed this bug by changing the of buff modification
# to 0.02 for tier 2.
# 
# Also fixed color of pulse effects. They were swapped (red
# vs green).

# NOTE: fixed small bug in original script where "Twin
# Disciplines" would not trigger if attack crit chance is
# exactly equal to spell crit chance. Rare, but possible.

# NOTE: green = attack damage
# 		red = spell damage


var attack_bt: BuffType
var spell_bt: BuffType
var red_pt: ProjectileType
var green_pt: ProjectileType

var red_flame_count: int = 0
var green_flame_count: int = 0


func get_tier_stats() -> Dictionary:
	return {
		1: {flame_dmg_ratio = 0.65, flame_dmg_ratio_add = 0.005, pulse_dmg_ratio = 0.55, pulse_dmg_ratio_add = 0.005, twin_disciplines_crit = 0.01},
		2: {flame_dmg_ratio = 0.75, flame_dmg_ratio_add = 0.010, pulse_dmg_ratio = 0.75, pulse_dmg_ratio_add = 0.010, twin_disciplines_crit = 0.02},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var flame_dmg_ratio: String = Utils.format_percent(_stats.flame_dmg_ratio, 2)
	var flame_dmg_ratio_add: String = Utils.format_percent(_stats.flame_dmg_ratio_add, 2)
	var pulse_dmg_ratio: String = Utils.format_percent(_stats.pulse_dmg_ratio, 2)
	var pulse_dmg_ratio_add: String = Utils.format_percent(_stats.pulse_dmg_ratio_add, 2)
	var twin_disciplines_crit: String = Utils.format_percent(_stats.twin_disciplines_crit, 2)
	var physical_string: String = AttackType.convert_to_colored_string(AttackType.enm.PHYSICAL)

	var list: Array[AbilityInfo] = []
	
	var twin_flames: AbilityInfo = AbilityInfo.new()
	twin_flames.name = "Twin Flames"
	twin_flames.icon = "res://resources/icons/orbs/orb_fire.tres"
	twin_flames.description_short = "On each attack, this tower has a chance equal to launch a green flame or a red flame. Flames can deal %s damage or spell damage\n" % physical_string
	twin_flames.description_full = "On each attack, this tower has a chance equal to its crit chance to launch a green flame, dealing %s of tower's attack damage as spell damage, and a chance equal to its spell crit chance to launch a red flame, dealing %s of tower's attack damage as %s damage.\n" % [flame_dmg_ratio, flame_dmg_ratio, physical_string] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % flame_dmg_ratio_add
	list.append(twin_flames)

	var twin_pulses: AbilityInfo = AbilityInfo.new()
	twin_pulses.name = "Twin Pulses"
	twin_pulses.icon = "res://resources/icons/tower_icons/fire_star.tres"
	twin_pulses.description_short = "Every time this tower has launched a lot of flames, it releases a pulse, dealing %s damage or spell damage to creeps in range.\n" % physical_string
	twin_pulses.description_full = "Every time this tower has launched 8 red flames, it releases a green pulse, dealing %s of its attack damage as spell damage in 900 AoE and every time it has launched 8 green flames, it releases a red pulse, dealing %s of its attack damage as %s damage in 900 AoE.\n" % [pulse_dmg_ratio, pulse_dmg_ratio, physical_string] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % pulse_dmg_ratio_add \
	+ "-1 flame needed at level 15 and 25\n"
	twin_pulses.radius = 900
	twin_pulses.target_type = TargetType.new(TargetType.CREEPS)
	list.append(twin_pulses)

	var twin_disciplines: AbilityInfo = AbilityInfo.new()
	twin_disciplines.name = "Twin Disciplines"
	twin_disciplines.icon = "res://resources/icons/swords/greatsword_03.tres"
	twin_disciplines.description_short = "Whenever this tower deals a critical hit to a creep, it gains bonus crit chance or spell crit chance.\n"
	twin_disciplines.description_full = "Whenever this tower deals a critical hit to a creep, it gains %s bonus critical chance or spell critical chance, both stacking up to 10 times, for 7 seconds. The lower chance will always be prioritized." % twin_disciplines_crit
	list.append(twin_disciplines)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	attack_bt = BuffType.new("attack_bt", 7, 0, true, self)
	var dave_physical_mod: Modifier = Modifier.new()
	dave_physical_mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.0, _stats.twin_disciplines_crit)
	attack_bt.set_buff_modifier(dave_physical_mod)
	attack_bt.set_buff_icon("res://resources/icons/generic_icons/hammer_drop.tres")
	attack_bt.set_buff_tooltip("Attack Discipline\nIncreases crit chance.")

	spell_bt = BuffType.new("spell_bt", 7, 0, true, self)
	var dave_spell_mod: Modifier = Modifier.new()
	dave_spell_mod.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.0, _stats.twin_disciplines_crit)
	spell_bt.set_buff_modifier(dave_spell_mod)
	spell_bt.set_buff_icon("res://resources/icons/generic_icons/ankh.tres")
	spell_bt.set_buff_tooltip("Spell Discipline\nIncreases spell crit chance.")

	red_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 1000, self)
	red_pt.set_event_on_interpolation_finished(red_pt_on_hit)

	green_pt = ProjectileType.create_interpolate("path_to_projectile_sprite", 1000, self)
	green_pt.set_event_on_interpolation_finished(green_pt_on_hit)



func on_attack(event: Event):
	var target: Unit = event.get_target()
	var attack_crit_chance: float = tower.get_prop_atk_crit_chance()
	var spell_crit_chance: float = tower.get_spell_crit_chance()
	var flame_count_for_pulse: int = get_flame_count_for_pulse()
	var pulse_damage: float = get_pulse_damage()

	if tower.calc_chance(spell_crit_chance):
		CombatLog.log_ability(tower, target, "Red Flame")

		Projectile.create_bezier_interpolation_from_unit_to_unit(red_pt, tower, 1, 1, tower, target, 0, 0.3, 0, true)
		red_flame_count += 1

	if tower.calc_chance(attack_crit_chance):
		CombatLog.log_ability(tower, target, "Green Flame")
		
		Projectile.create_bezier_interpolation_from_unit_to_unit(green_pt, tower, 1, 1, tower, target, 0, -0.3, 0, true)
		green_flame_count += 1

	var do_red_pulse: bool = red_flame_count >= flame_count_for_pulse
	var do_green_pulse: bool = green_flame_count >= flame_count_for_pulse

	if do_red_pulse:
		CombatLog.log_ability(tower, null, "Red Pulse")
		
		red_flame_count = 0

		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 900)

		while true:
			var creep: Unit = it.next()

			if creep == null:
				break

			tower.do_spell_damage(creep, pulse_damage, tower.calc_spell_crit_no_bonus())
			SFX.sfx_on_unit(SfxPaths.FIRE_BALL, creep, Unit.BodyPart.CHEST)
			var effect: int = Effect.create_colored("ZombifyTarget.mdl", Vector3(tower.get_x() - 48, tower.get_y() + 48, tower.get_z()), 0.0, 5, Color.RED)
			Effect.set_lifetime(effect, 0.5)

	if do_green_pulse:
		CombatLog.log_ability(tower, null, "Green Pulse")
		
		green_flame_count = 0
		
		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 900)

		while true:
			var creep: Unit = it.next()

			if creep == null:
				break

			tower.do_attack_damage(creep, pulse_damage, tower.calc_attack_multicrit_no_bonus())
			SFX.sfx_on_unit(SfxPaths.FIRE_SPLASH, creep, Unit.BodyPart.CHEST)
			var effect: int = Effect.create_colored("ZombifyTarget.mdl", Vector3(tower.get_x() + 48, tower.get_y() + 48, tower.get_z()), 0.0, 5, Color.GREEN)
			Effect.set_lifetime(effect, 0.5)


func on_damage(event: Event):
	if !event.is_attack_damage_critical():
		return

	var physical_buff: Buff = tower.get_buff_of_type(attack_bt)
	var spell_buff: Buff = tower.get_buff_of_type(spell_bt)
	var attack_crit_chance: float = tower.get_prop_atk_crit_chance()
	var spell_crit_chance: float = tower.get_spell_crit_chance()

	var physical_buff_level: int
	if physical_buff != null:
		physical_buff_level = physical_buff.get_level()
	else:
		physical_buff_level = 0

	var spell_buff_level: int
	if spell_buff != null:
		spell_buff_level = spell_buff.get_level()
	else:
		spell_buff_level = 0

	if attack_crit_chance <= spell_crit_chance || spell_buff_level == 10:
		if physical_buff == null:
			attack_bt.apply(tower, tower, 1)
		else:
			var new_buff_level: int = min(physical_buff_level + 1, 10)
			attack_bt.apply(tower, tower, new_buff_level)

		physical_buff = tower.get_buff_of_type(attack_bt)
		physical_buff.set_displayed_stacks(physical_buff.get_level())
	elif attack_crit_chance > spell_crit_chance || physical_buff_level == 10:
		if spell_buff == null:
			spell_bt.apply(tower, tower, 1)
		else:
			var new_buff_level: int = min(spell_buff_level + 1, 10)
			spell_bt.apply(tower, tower, new_buff_level)

		spell_buff = tower.get_buff_of_type(spell_bt)
		spell_buff.set_displayed_stacks(spell_buff.get_level())


func red_pt_on_hit(_projectile: Projectile, creep: Unit):
	if creep == null:
		return

	var damage: float = get_flame_damage()
	tower.do_attack_damage(creep, damage, tower.calc_attack_multicrit_no_bonus())


func green_pt_on_hit(_projectile: Projectile, creep: Unit):
	if creep == null:
		return

	var damage: float = get_flame_damage()
	tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())


func get_flame_count_for_pulse() -> int:
	var flame_count: int
	if tower.get_level() < 15:
		flame_count = 8
	elif tower.get_level() < 25:
		flame_count = 7
	else:
#		implicit "if tower.get_level() == 25"
		flame_count = 6

	return flame_count


func get_flame_damage() -> float:
	var level: int = tower.get_level()
	var current_attack_damage: float = tower.get_current_attack_damage_with_bonus()
	var damage_ratio: float = _stats.flame_dmg_ratio + _stats.flame_dmg_ratio_add * level
	var damage: float = current_attack_damage * damage_ratio

	return damage


func get_pulse_damage() -> float:
	var level: int = tower.get_level()
	var current_attack_damage: float = tower.get_current_attack_damage_with_bonus()
	var damage_ratio: float = _stats.pulse_dmg_ratio + _stats.pulse_dmg_ratio_add * level
	var damage: float = current_attack_damage * damage_ratio

	return damage
