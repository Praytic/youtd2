extends Tower


# NOTE: original script appears to have a bug. Twin
# Disciplines is supposed to give 1% per stack for tier 1
# and 2% per stack for tier 2. The script adds +1 to buff
# level per stack for both tiers, so both tiers add 1% per
# stack. Fixed this bug by changing the of buff modification
# to 0.02 for tier 2.
# 
# Also fixed color of pulse effects. They were swapped (red
# vs green).

# NOTE: green = attack damage
# 		red = spell damage


var dave_physical_bt: BuffType
var dave_spell_bt: BuffType
var dave_red_pt: ProjectileType
var dave_green_pt: ProjectileType

var red_flame_count: int = 0
var green_flame_count: int = 0


func get_tier_stats() -> Dictionary:
	return {
		1: {flame_dmg_ratio = 0.65, flame_dmg_ratio_add = 0.005, pulse_dmg_ratio = 0.55, pulse_dmg_ratio_add = 0.005, twin_disciplines_crit = 0.01},
		2: {flame_dmg_ratio = 0.75, flame_dmg_ratio_add = 0.010, pulse_dmg_ratio = 0.75, pulse_dmg_ratio_add = 0.010, twin_disciplines_crit = 0.02},
	}


func get_ability_description() -> String:
	var flame_dmg_ratio: String = Utils.format_percent(_stats.flame_dmg_ratio, 2)
	var flame_dmg_ratio_add: String = Utils.format_percent(_stats.flame_dmg_ratio_add, 2)
	var pulse_dmg_ratio: String = Utils.format_percent(_stats.pulse_dmg_ratio, 2)
	var pulse_dmg_ratio_add: String = Utils.format_percent(_stats.pulse_dmg_ratio_add, 2)
	var twin_disciplines_crit: String = Utils.format_percent(_stats.twin_disciplines_crit, 2)

	var text: String = ""

	text += "[color=GOLD]Twin Flames[/color]\n"
	text += "On each attack, this tower has a chance equal to its crit chance to launch a green flame, dealing %s of tower's attack damage as spell damage, and a chance equal to its spell crit chance to launch a red flame, dealing %s of tower's attack damage as physical damage.\n" % [flame_dmg_ratio, flame_dmg_ratio]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % flame_dmg_ratio_add
	text += " \n"

	text += "[color=GOLD]Twin Pulses[/color]\n"
	text += "Every time this tower has launched 8 red flames, it releases a green pulse, dealing %s of its attack damage as spell damage in 900 AoE and every time it has launched 8 green flames, it releases a red pulse, dealing %s of its attack damage as physical damage in 900 AoE.\n" % [pulse_dmg_ratio, pulse_dmg_ratio]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % pulse_dmg_ratio_add
	text += "-1 flame needed at level 15 and 25\n"
	text += " \n"

	text += "[color=GOLD]Twin Disciplines[/color]\n"
	text += "Each time it scores a critical hit with an attack, this tower gains %s bonus critical chance or spell critical chance, both stacking up to 10 times, for 7 seconds. The lower chance will always be prioritized." % twin_disciplines_crit

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Twin Flames[/color]\n"
	text += "On each attack, this tower has a chance equal to launch a green flame or a red flame.\n"
	text += " \n"

	text += "[color=GOLD]Twin Pulses[/color]\n"
	text += "Every time this tower has launched a lot of flames, it releases a pulse, dealing damage to creeps in range.\n"
	text += " \n"

	text += "[color=GOLD]Twin Disciplines[/color]\n"
	text += "Each time it scores a critical hit with an attack, this tower gains bonus crit chance or spell crit chance."

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	dave_physical_bt = BuffType.new("dave_physical_bt", 7, 0, true, self)
	var dave_physical_mod: Modifier = Modifier.new()
	dave_physical_mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.0, _stats.twin_disciplines_crit)
	dave_physical_bt.set_buff_modifier(dave_physical_mod)
	dave_physical_bt.set_buff_icon("@@1@@")
	dave_physical_bt.set_buff_tooltip("Attack Discipline\nThis tower has Attack Discipline; it has increased crit chance.")

	dave_spell_bt = BuffType.new("dave_spell_bt", 7, 0, true, self)
	var dave_spell_mod: Modifier = Modifier.new()
	dave_spell_mod.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.0, _stats.twin_disciplines_crit)
	dave_spell_bt.set_buff_modifier(dave_spell_mod)
	dave_spell_bt.set_buff_icon("@@0@@")
	dave_spell_bt.set_buff_tooltip("Spell Discipline\nThis tower has Spell Discipline; it has increased spell crit chance.")

	dave_red_pt = ProjectileType.create("RedDragonMissile.mdl", 4, 1000, self)
	dave_red_pt.set_event_on_interpolation_finished(dave_red_pt_on_hit)

	dave_green_pt = ProjectileType.create("GreenDragonMissile.mdl", 4, 1000, self)
	dave_green_pt.set_event_on_interpolation_finished(dave_green_pt_on_hit)



func on_attack(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var attack_crit_chance: float = tower.get_prop_atk_crit_chance()
	var spell_crit_chance: float = tower.get_spell_crit_chance()
	var flame_count_for_pulse: int = get_flame_count_for_pulse()
	var pulse_damage: float = get_pulse_damage()

	if tower.calc_chance(spell_crit_chance):
		Projectile.create_bezier_interpolation_from_unit_to_unit(dave_red_pt, tower, 1, 1, tower, target, 0, 0.3, 0, true)
		red_flame_count += 1

	if tower.calc_chance(attack_crit_chance):
		Projectile.create_bezier_interpolation_from_unit_to_unit(dave_green_pt, tower, 1, 1, tower, target, 0, -0.3, 0, true)
		green_flame_count += 1

	var do_red_pulse: bool = red_flame_count >= flame_count_for_pulse
	var do_green_pulse: bool = green_flame_count >= flame_count_for_pulse

	if do_red_pulse:
		red_flame_count = 0

		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 900)

		while true:
			var creep: Unit = it.next()

			if creep == null:
				break

			tower.do_spell_damage(creep, pulse_damage, tower.calc_spell_crit_no_bonus())
			SFX.sfx_on_unit("ImmolationDamage.mdl", creep, "chest")
			var effect: int = Effect.create_colored("ZombifyTarget.mdl", tower.get_visual_x() - 48, tower.get_visual_y() + 48, 40, 0.0, 0.42, Color.RED)
			Effect.set_lifetime(effect, 0.5)

	if do_green_pulse:
		green_flame_count = 0
		
		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 900)

		while true:
			var creep: Unit = it.next()

			if creep == null:
				break

			tower.do_attack_damage(creep, pulse_damage, tower.calc_attack_multicrit_no_bonus())
			SFX.sfx_on_unit("FlameStrikeEmbers.mdl", creep, "chest")
			var effect: int = Effect.create_colored("ZombifyTarget.mdl", tower.get_visual_x() + 48, tower.get_visual_y() + 48, 40, 0.0, 0.42, Color.GREEN)
			Effect.set_lifetime(effect, 0.5)


func on_damage(event: Event):
	if !event.is_attack_damage_critical():
		return

	var tower: Tower = self
	var physical_buff: Buff = tower.get_buff_of_type(dave_physical_bt)
	var spell_buff: Buff = tower.get_buff_of_type(dave_spell_bt)
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

	if attack_crit_chance < spell_crit_chance || spell_buff_level == 10:
		if physical_buff == null:
			dave_physical_bt.apply(tower, tower, 1)
		else:
			var new_buff_level: int = min(physical_buff_level + 1, 10)
			dave_physical_bt.apply(tower, tower, new_buff_level)
	elif attack_crit_chance > spell_crit_chance || physical_buff_level == 10:
		if spell_buff == null:
			dave_spell_bt.apply(tower, tower, 1)
		else:
			var new_buff_level: int = min(spell_buff_level + 1, 10)
			dave_spell_bt.apply(tower, tower, new_buff_level)


func dave_red_pt_on_hit(_projectile: Projectile, creep: Unit):
	var tower: Tower = self
	var damage: float = get_flame_damage()
	tower.do_attack_damage(creep, damage, tower.calc_attack_multicrit_no_bonus())


func dave_green_pt_on_hit(_projectile: Projectile, creep: Unit):
	var tower: Tower = self
	var damage: float = get_flame_damage()
	tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())


func get_flame_count_for_pulse() -> int:
	var tower: Tower = self

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
	var tower: Tower = self
	var level: int = tower.get_level()
	var current_attack_damage: float = tower.get_current_attack_damage_with_bonus()
	var damage_ratio: float = _stats.flame_dmg_ratio + _stats.flame_dmg_ratio_add * level
	var damage: float = current_attack_damage * damage_ratio

	return damage


func get_pulse_damage() -> float:
	var tower: Tower = self
	var level: int = tower.get_level()
	var current_attack_damage: float = tower.get_current_attack_damage_with_bonus()
	var damage_ratio: float = _stats.pulse_dmg_ratio + _stats.pulse_dmg_ratio_add * level
	var damage: float = current_attack_damage * damage_ratio

	return damage
