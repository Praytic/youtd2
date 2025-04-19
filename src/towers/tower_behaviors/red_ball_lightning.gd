extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {shock_damage = 1200, shock_damage_add = 48, mod_spell_damage = 0.20, mod_spell_damage_add = 0.004},
		2: {shock_damage = 3500, shock_damage_add = 140, mod_spell_damage = 0.35, mod_spell_damage_add = 0.006},
	}

const SHOCK_CHANCE: float = 0.30
const SHOCK_CHANCE_ADD: float = 0.005
const SHOCK_CRIT_CHANCE: float = 0.10
const SHOCK_CRIT_DAMAGE: float = 0.60


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_SPELL_DAMAGE_DEALT, _stats.mod_spell_damage, _stats.mod_spell_damage_add)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/azul_flake.tres")
	aura_bt.set_buff_tooltip(tr("DG3B"))


func on_damage(event: Event):
	var creep: Unit = event.get_target()
	var shock_chance: float = SHOCK_CHANCE + SHOCK_CHANCE_ADD * tower.get_level()
	var shock_damage: float = _stats.shock_damage + _stats.shock_damage_add * tower.get_level()
	var shock_crit_ratio: float = tower.calc_spell_crit(0.1, 0.6)

	if !tower.calc_chance(shock_chance):
		return

	CombatLog.log_ability(tower, creep, "Lightning Shock")

	var lightning: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, tower, creep)
	lightning.modulate = Color.RED
	lightning.set_lifetime(0.2)

	tower.do_spell_damage(creep, shock_damage, shock_crit_ratio)
