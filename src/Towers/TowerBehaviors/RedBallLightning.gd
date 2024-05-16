extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {bounce_count = 2, shock_damage = 1200, shock_damage_add = 48, mod_spell_damage = 0.20, mod_spell_damage_add = 0.004},
		2: {bounce_count = 3, shock_damage = 3500, shock_damage_add = 140, mod_spell_damage = 0.35, mod_spell_damage_add = 0.006},
	}

const AURA_RANGE: int = 250
const SHOCK_CHANCE: float = 0.30
const SHOCK_CHANCE_ADD: float = 0.005
const SHOCK_CRIT_CHANCE: float = 0.10
const SHOCK_CRIT_DAMAGE: float = 0.60


func get_ability_info_list() -> Array[AbilityInfo]:
	var shock_chance: String = Utils.format_percent(SHOCK_CHANCE, 2)
	var shock_chance_add: String = Utils.format_percent(SHOCK_CHANCE_ADD, 2)
	var shock_damage: String = Utils.format_float(_stats.shock_damage, 2)
	var shock_damage_add: String = Utils.format_float(_stats.shock_damage_add, 2)
	var shock_crit_chance: String = Utils.format_percent(SHOCK_CRIT_CHANCE, 2)
	var shock_crit_damage: String = Utils.format_percent(SHOCK_CRIT_DAMAGE, 2)

	var list: Array[AbilityInfo] = []
	
	var lightning_shock: AbilityInfo = AbilityInfo.new()
	lightning_shock.name = "Lightning Shock"
	lightning_shock.icon = "res://resources/icons/electricity/lightning_glowing.tres"
	lightning_shock.description_short = "Whenever this tower hits a creep, it has a chance to release a [color=GOLD]Lightning Shock[/color] on attacked creeps, dealing spell damage.\n"
	lightning_shock.description_full = "Whenever this tower hits a creep, it has a %s chance to release a [color=GOLD]Lightning Shock[/color] on attacked creeps. [color=GOLD]Lightning Shock[/color] deals %s spell damage and has a %s bonus chance to crit with %s bonus spell damage.\n" % [shock_chance, shock_damage, shock_crit_chance, shock_crit_damage] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s chance\n" % shock_chance_add \
	+ "+%s spell damage\n" % shock_damage_add
	list.append(lightning_shock)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	tower.set_attack_style_bounce(_stats.bounce_count, 0.60)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.0, 0.0001)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/GenericIcons/azul_flake.tres")
	aura_bt.set_buff_tooltip("Lightning Charge Aura\nIncreases spell damage.")


func get_aura_types() -> Array[AuraType]:
	var aura_level: int = int(_stats.mod_spell_damage * 10000)
	var aura_level_add: int = int(_stats.mod_spell_damage_add * 10000)

	var aura: AuraType = AuraType.new()

	var mod_spell_damage: String = Utils.format_percent(_stats.mod_spell_damage, 2)
	var mod_spell_damage_add: String = Utils.format_percent(_stats.mod_spell_damage_add, 2)
	
	aura.name = "Lightning Charge"
	aura.icon = "res://resources/icons/TowerIcons/BallLightningAccelerator.tres"
	aura.description_short = "Towers in range have their spell damage increased.\n"
	aura.description_full = "Towers in %d range have their spell damage increased by %s.\n" % [AURA_RANGE, mod_spell_damage] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage\n" % mod_spell_damage_add

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = aura_level
	aura.level_add = aura_level_add
	aura.power = aura_level
	aura.power_add = aura_level_add
	aura.aura_effect = aura_bt
	return [aura]


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
