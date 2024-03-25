extends TowerBehavior


var sir_golem_aura_bt: BuffType
var sir_golem_slow_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Ground Smash[/color]\n"
	text += "On damage this tower deals 4300 decay damage to all creeps in 750 range around it, slowing them by 60% for 0.5 seconds.\n"
	text += " \n"
	text += "[color=GOLD]Hint:[/color] The damage of this ability is improved by spell damage.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+230 damage\n"
	text += "+0.012 seconds slow duration\n"
	text += "+50 range at level 25.\n"
	text += " \n"

	text += "[color=GOLD]Earthquake Aura - Aura[/color]\n"
	text += "Towers in 150 range around the Mud Golem have a 3% attackspeed adjusted chance on attack to trigger Ground Smash.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.04% chance\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Ground Smash[/color]\n"
	text += "Damages all creeps in range and slows them.\n"
	text += " \n"

	text += "[color=GOLD]Earthquake Aura - Aura[/color]\n"
	text += "Towers in range have a chance to trigger Ground Smash.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	tower.set_attack_ground_only()


func tower_init():
	sir_golem_slow_bt = BuffType.new("sir_golem_slow_bt", 0.5, 0.012, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.60, 0.0)
	sir_golem_slow_bt.set_buff_modifier(mod)
	sir_golem_slow_bt.set_buff_icon("@@0@@")
	sir_golem_slow_bt.set_buff_tooltip("Smashed\nReduces movement speed.")

	sir_golem_aura_bt = BuffType.create_aura_effect_type("sir_golem_aura_bt", true, self)
	sir_golem_aura_bt.set_buff_icon("@@1@@")
	sir_golem_aura_bt.add_event_on_attack(sir_golem_aura_bt_on_attack)
	sir_golem_aura_bt.set_buff_tooltip("Earthquake Aura\nChance to trigger Ground Smash.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 150
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 0
	aura.power = 0
	aura.power_add = 0
	aura.aura_effect = sir_golem_aura_bt

	return [aura]


func on_damage(_event: Event):
	CombatLog.log_ability(tower, null, "Ground Smash")

	smash()


func sir_golem_aura_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Tower = buff.get_buffed_unit()
	var ground_smash_chance: float = (0.03 + 0.0004 * tower.get_level()) * buffed_tower.get_base_attackspeed()

	if !buffed_tower.calc_chance(ground_smash_chance):
		return

	CombatLog.log_ability(buffed_tower, null, "Ground Smash")

	smash()


func smash():
	var level: int = tower.get_level()
	var smash_damage: float = (4300 + 230 * level) * tower.get_prop_spell_damage_dealt()

	var smash_range: float
	if level == 25:
		smash_range = 800
	else:
		smash_range = 750

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), smash_range)
	
	while true:
		var next: Unit = it.next()

		if next == null:
			break

		if next.get_size() == CreepSize.enm.AIR:
			continue

#		NOTE: using do_attack_damage() with args based on
#		spell damage is not a typo. Written this way in
#		original script on purpose.
		sir_golem_slow_bt.apply(tower, next, level)
		tower.do_attack_damage(next, smash_damage, tower.calc_spell_crit_no_bonus())
