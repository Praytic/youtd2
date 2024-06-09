extends TowerBehavior


var aura_bt: BuffType

const AURA_RANGE: int = 200
const UNSTABLE_MANA_RATIO: float = 0.75
const UNSTABLE_MANA_RATIO_ADD: float = 0.01


func get_tier_stats() -> Dictionary:
	return {
		1: {mana_burn_amount = 2, damage_per_mana_burned = 50, damage_per_mana_burned_add = 4, mana_regen_add = 1.0, aura_mana_cost = 7, damage_mana_multiplier = 8.0},
		2: {mana_burn_amount = 3, damage_per_mana_burned = 75, damage_per_mana_burned_add = 6, mana_regen_add = 2.4, aura_mana_cost = 14, damage_mana_multiplier = 9.5},
		3: {mana_burn_amount = 4, damage_per_mana_burned = 100, damage_per_mana_burned_add = 8, mana_regen_add = 4.2, aura_mana_cost = 24, damage_mana_multiplier = 11.0},
		4: {mana_burn_amount = 5, damage_per_mana_burned = 125, damage_per_mana_burned_add = 10, mana_regen_add = 6.4, aura_mana_cost = 35, damage_mana_multiplier = 12.5},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var damage_mana_multiplier: String = Utils.format_float(_stats.damage_mana_multiplier, 2)
	var elemental_attack_type_string: String = AttackType.convert_to_colored_string(AttackType.enm.ELEMENTAL)
	var unstable_mana_ratio: String = Utils.format_percent(UNSTABLE_MANA_RATIO, 2)
	var unstable_mana_ratio_add: String = Utils.format_percent(UNSTABLE_MANA_RATIO_ADD, 2)

	var list: Array[AbilityInfo] = []
	
	var unstable_energies: AbilityInfo = AbilityInfo.new()
	unstable_energies.name = "Unstable Energies"
	unstable_energies.icon = "res://resources/icons/electricity/electricity_yellow.tres"
	unstable_energies.description_short = "Whenever this tower hits a creep, it has a chance to release a powerful energy blast at the cost of some mana, dealing %s damage.\n" % elemental_attack_type_string
	unstable_energies.description_full = "Whenever this tower hits a creep, it has a 28%% chance to release a powerful energy blast, dealing [color=GOLD][current mana x %s][/color] %s damage to the target, but consuming %s of its own current mana.\n" % [damage_mana_multiplier, elemental_attack_type_string, unstable_mana_ratio] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.48% chance\n" \
	+ "-%s current mana consumed\n" % [unstable_mana_ratio_add]
	list.append(unstable_energies)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0, _stats.mana_regen_add)


func drake_aura_manaburn(event: Event):
	var b: Buff = event.get_buff()
	var buffed_tower: Unit = b.get_buffed_unit()
	var target: Unit = event.get_target()
	var caster: Unit = b.get_caster()
	var speed_and_range_adjust: float = buffed_tower.get_base_attack_speed() * 800 / buffed_tower.get_range()
	var mana_cost_for_drake: float = _stats.aura_mana_cost * speed_and_range_adjust
	var mana_burned_intended: float = _stats.mana_burn_amount * speed_and_range_adjust
	var level: int = caster.get_level()

	if target.get_mana() > 0 && caster.subtract_mana(mana_cost_for_drake, false) > 0:
		var mana_burned_actual: float = target.subtract_mana(mana_burned_intended, true)

		var damage_per_mana_burned: float = _stats.damage_per_mana_burned + _stats.damage_per_mana_burned_add * level
		var damage: float = mana_burned_actual * damage_per_mana_burned
		
		buffed_tower.do_spell_damage(target, damage, buffed_tower.calc_spell_crit_no_bonus())
		SFX.sfx_at_unit("DeathandDecayDamage.dml", target)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/moebius_trefoil.tres")
	aura_bt.add_event_on_attack(drake_aura_manaburn)
	aura_bt.set_buff_tooltip("Mana Distortion Field\nMana burns creeps on attack.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var mana_burn_amount: String = Utils.format_float(_stats.mana_burn_amount, 2)
	var aura_mana_cost: String = Utils.format_float(_stats.aura_mana_cost, 2)
	var damage_per_mana_burned: String = Utils.format_float(_stats.damage_per_mana_burned, 2)
	var damage_per_mana_burned_add: String = Utils.format_float(_stats.damage_per_mana_burned_add, 2)

	aura.name = "Mana Distortion Field"
	aura.icon = "res://resources/icons/magic/magic_stone.tres"
	aura.description_short = "Whenever a nearby tower attacks, it burns mana from the main target and deals spell damage to it. The mana burn costs the Drake some mana.\n"
	aura.description_full = "Whenever a tower in %d range attacks, it burns %s mana from the main target. The mana burn costs the Drake %s mana. The mana burned and spent is attack speed and range adjusted and the buffed tower deals %s spell damage per mana point burned.\n" % [AURA_RANGE, mana_burn_amount, aura_mana_cost, damage_per_mana_burned] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage per mana point burned\n" % damage_per_mana_burned_add

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = aura_bt
	return [aura]


func on_damage(event: Event):
	if !tower.calc_chance(0.28 + 0.0048 * tower.get_level()):
		return

	CombatLog.log_ability(tower, event.get_target(), "Unstable Energies")

	var target: Unit = event.get_target()
	var tower_mana: float = tower.get_mana()
	var level: int = tower.get_level()
	var damage: float = _stats.damage_mana_multiplier * tower_mana
	var mana_spent: float = tower_mana * (UNSTABLE_MANA_RATIO - UNSTABLE_MANA_RATIO_ADD * level)

	tower.do_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus())
	tower.subtract_mana(mana_spent, true)
	SFX.sfx_at_unit("AlmaTarget.dml", target)
