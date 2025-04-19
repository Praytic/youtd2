extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed bug where Twin Disciplines
# gave 1% per stack for tier 2 tower, even though it's
# supposed to be 2% according to ability description. Fixed
# this bug by changing the level_add part of buff
# modification to 0.02 for tier 2.
# 
# Also fixed color of pulse effects. They were swapped (red
# vs green).

# NOTE: [ORIGINAL_GAME_BUG] Fixed small bug in original
# script where "Twin Disciplines" would not trigger if
# attack crit chance is exactly equal to spell crit chance.
# Rare, but possible.

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


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	attack_bt = BuffType.new("attack_bt", 7, 0, true, self)
	var dave_physical_mod: Modifier = Modifier.new()
	dave_physical_mod.add_modification(ModificationType.enm.MOD_ATK_CRIT_CHANCE, 0.0, _stats.twin_disciplines_crit)
	attack_bt.set_buff_modifier(dave_physical_mod)
	attack_bt.set_buff_icon("res://resources/icons/generic_icons/hammer_drop.tres")
	attack_bt.set_buff_tooltip(tr("GAL7"))

	spell_bt = BuffType.new("spell_bt", 7, 0, true, self)
	var dave_spell_mod: Modifier = Modifier.new()
	dave_spell_mod.add_modification(ModificationType.enm.MOD_SPELL_CRIT_CHANCE, 0.0, _stats.twin_disciplines_crit)
	spell_bt.set_buff_modifier(dave_spell_mod)
	spell_bt.set_buff_icon("res://resources/icons/generic_icons/ankh.tres")
	spell_bt.set_buff_tooltip(tr("VKU9"))

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
			SFX.sfx_at_unit(SfxPaths.FIRE_BALL, creep)

			var effect_target: int = Effect.create_simple_at_unit_attached("res://src/effects/immolation_damage.tscn", creep, Unit.BodyPart.CHEST)
			Effect.set_color(effect_target, Color.RED)

			var effect_caster: int = Effect.create_colored("res://src/effects/zombify_target.tscn", Vector3(tower.get_x() - 48, tower.get_y() + 48, tower.get_z() + 80), 0.0, 1, Color.RED)
			Effect.set_lifetime(effect_caster, 0.5)

	if do_green_pulse:
		CombatLog.log_ability(tower, null, "Green Pulse")
		
		green_flame_count = 0
		
		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 900)

		while true:
			var creep: Unit = it.next()

			if creep == null:
				break

			tower.do_attack_damage(creep, pulse_damage, tower.calc_attack_multicrit_no_bonus())
			SFX.sfx_at_unit(SfxPaths.FIRE_SPLASH, creep)
			
			var effect_target: int = Effect.create_simple_at_unit_attached("res://src/effects/flame_strike_embers.tscn", creep, Unit.BodyPart.CHEST)
			Effect.set_color(effect_target, Color.GREEN)

			var effect_caster: int = Effect.create_colored("res://src/effects/zombify_target.tscn", Vector3(tower.get_x() + 48, tower.get_y() + 48, tower.get_z() + 80), 0.0, 1, Color.GREEN)
			Effect.set_lifetime(effect_caster, 0.5)


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
