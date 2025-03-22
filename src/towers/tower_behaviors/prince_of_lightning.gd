extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {strike_chance = 0.15, strike_damage = 2000, strike_damage_add = 100, mod_dmg_from_storm = 0.10, mod_dmg_from_storm_add = 0.002},
		2: {strike_chance = 0.20, strike_damage = 4000, strike_damage_add = 200, mod_dmg_from_storm = 0.15, mod_dmg_from_storm_add = 0.004},
	}

const STRIKE_CHANCE_ADD: float = 0.004


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_FROM_STORM, _stats.mod_dmg_from_storm, _stats.mod_dmg_from_storm_add)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/over_infinity.tres")
	aura_bt.set_buff_tooltip(tr("DELR"))


func on_damage(event: Event):
	var creep: Unit = event.get_target()
	var strike_chance: float = _stats.strike_chance + STRIKE_CHANCE_ADD * tower.get_level()
	var strike_damage: float = _stats.strike_damage + _stats.strike_damage_add * tower.get_level()

	if !tower.calc_chance(strike_chance):
		return

	CombatLog.log_ability(tower, creep, "Lightning Strike")

	tower.do_spell_damage(creep, strike_damage, tower.calc_spell_crit_no_bonus())
	Effect.create_simple_at_unit("res://src/effects/monsoon_bolt.tscn", creep, Unit.BodyPart.ORIGIN)
