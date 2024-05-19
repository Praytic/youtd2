extends TowerBehavior


var aura_bt: BuffType
var slow_bt: BuffType

const AURA_RANGE: int = 150


func get_ability_info_list() -> Array[AbilityInfo]:
	var decay_string: String = AttackType.convert_to_colored_string(AttackType.enm.DECAY)

	var list: Array[AbilityInfo] = []
	
	var ground_smash: AbilityInfo = AbilityInfo.new()
	ground_smash.name = "Ground Smash"
	ground_smash.icon = "res://resources/icons/swords/greatsword_02.tres"
	ground_smash.description_short = "Whenever this tower hits a creep, it deals AoE %s damage and slows affected. This damage is improved by the spell damage dealt stat.\n" % decay_string
	ground_smash.description_full = "Whenever this tower hits a creep, it deals 4300 %s damage to all creeps in 750 range and slows them by 60%% for 0.5 seconds.\n" % decay_string \
	+ " \n" \
	+ "[color=GOLD]Hint:[/color] The damage of this ability is improved by the spell damage dealt stat.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+230 damage\n" \
	+ "+0.012 seconds slow duration\n" \
	+ "+50 range at level 25.\n"
	list.append(ground_smash)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	tower.set_attack_ground_only()


func tower_init():
	slow_bt = BuffType.new("slow_bt", 0.5, 0.012, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.60, 0.0)
	slow_bt.set_buff_modifier(mod)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/hammer_drop.tres")
	slow_bt.set_buff_tooltip("Smashed\nReduces movement speed.")

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/cog.tres")
	aura_bt.add_event_on_attack(aura_bt_on_attack)
	aura_bt.set_buff_tooltip("Earthquake Aura\nChance to trigger Ground Smash.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Earthquake Aura"
	aura.icon = "res://resources/icons/tower_icons/fire_battery.tres"
	aura.description_short = "Towers in range have a chance to trigger [color=GOLD]Ground Smash[/color].\n"
	aura.description_full = "Towers in %d range around the Mud Golem have a 3%% attack speed adjusted chance on attack to trigger [color=GOLD]Ground Smash[/color].\n" % AURA_RANGE \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.04% chance\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 0
	aura.power = 0
	aura.power_add = 0
	aura.aura_effect = aura_bt

	return [aura]


func on_damage(_event: Event):
	CombatLog.log_ability(tower, null, "Ground Smash")

	smash()


func aura_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Tower = buff.get_buffed_unit()
	var ground_smash_chance: float = (0.03 + 0.0004 * tower.get_level()) * buffed_tower.get_base_attack_speed()

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
		slow_bt.apply(tower, next, level)
		tower.do_attack_damage(next, smash_damage, tower.calc_spell_crit_no_bonus())
