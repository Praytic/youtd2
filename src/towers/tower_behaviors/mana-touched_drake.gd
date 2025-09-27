extends TowerBehavior


var aura_bt: BuffType

const UNSTABLE_MANA_RATIO: float = 0.75
const UNSTABLE_MANA_RATIO_ADD: float = 0.01


func get_tier_stats() -> Dictionary:
	return {
		1: {mana_burn_amount = 2, damage_per_mana_burned = 50, damage_per_mana_burned_add = 4, aura_mana_cost = 7, damage_mana_multiplier = 8.0},
		2: {mana_burn_amount = 3, damage_per_mana_burned = 75, damage_per_mana_burned_add = 6, aura_mana_cost = 14, damage_mana_multiplier = 9.5},
		3: {mana_burn_amount = 4, damage_per_mana_burned = 100, damage_per_mana_burned_add = 8, aura_mana_cost = 24, damage_mana_multiplier = 11.0},
		4: {mana_burn_amount = 5, damage_per_mana_burned = 125, damage_per_mana_burned_add = 10, aura_mana_cost = 35, damage_mana_multiplier = 12.5},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func drake_aura_manaburn(event: Event):
	var b: Buff = event.get_buff()
	var buffed_tower: Unit = b.get_buffed_unit()
	var target: Unit = event.get_target()
	var caster: Unit = b.get_caster()
	var speed_and_range_adjust: float = buffed_tower.get_base_attack_speed() * 800 / buffed_tower.get_base_range()
	var mana_cost_for_drake: float = _stats.aura_mana_cost * speed_and_range_adjust
	var mana_burned_intended: float = _stats.mana_burn_amount * speed_and_range_adjust
	var level: int = caster.get_level()

	if target.get_mana() > 0 && caster.subtract_mana(mana_cost_for_drake, false) > 0:
		var mana_burned_actual: float = target.subtract_mana(mana_burned_intended, true)

		var damage_per_mana_burned: float = _stats.damage_per_mana_burned + _stats.damage_per_mana_burned_add * level
		var damage: float = mana_burned_actual * damage_per_mana_burned
		
		buffed_tower.do_spell_damage(target, damage, buffed_tower.calc_spell_crit_no_bonus())
		Effect.create_simple_at_unit("res://src/effects/spell_aima.tscn", target)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/moebius_trefoil.tres")
	aura_bt.add_event_on_attack(drake_aura_manaburn)
	aura_bt.set_buff_tooltip(tr("Z3II"))


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
	Effect.create_simple_at_unit("res://src/effects/death_and_decay.tscn", target)
