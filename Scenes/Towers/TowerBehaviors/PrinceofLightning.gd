extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_spell_crit_add = 0.0025, strike_chance = 0.15, strike_damage = 2000, strike_damage_add = 100, mod_dmg_from_storm = 0.10, mod_dmg_from_storm_add = 0.002},
		2: {mod_spell_crit_add = 0.0050, strike_chance = 0.20, strike_damage = 4000, strike_damage_add = 200, mod_dmg_from_storm = 0.15, mod_dmg_from_storm_add = 0.004},
	}

const STRIKE_CHANCE_ADD: float = 0.004
const AURA_RANGE: float = 1300


func get_ability_info_list() -> Array[AbilityInfo]:
	var strike_chance: String = Utils.format_percent(_stats.strike_chance, 2)
	var strike_chance_add: String = Utils.format_percent(STRIKE_CHANCE_ADD, 2)
	var strike_damage: String = Utils.format_float(_stats.strike_damage, 2)
	var strike_damage_add: String = Utils.format_float(_stats.strike_damage_add, 2)
	var list: Array[AbilityInfo] = []
	
	var lightning: AbilityInfo = AbilityInfo.new()
	lightning.name = "Lightning Strike"
	lightning.icon = "res://Resources/Icons/electricity/lightning_glowing.tres"
	lightning.description_short = "Whenever this tower hits a creep, there is a chance that a lightning bolt strikes the target, dealing spell damage.\n"
	lightning.description_full = "Whenever this tower hits a creep, there is a %s chance that a lightning bolt strikes the target for %s spell damage.\n" % [strike_chance, strike_damage] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage\n" % strike_damage_add \
	+ "+%s chance\n" % strike_chance_add
	list.append(lightning)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


# NOTE: this tower's tooltip in original game includes
# innate stats in some cases
# spell crit chance = yes
# spell crit chance add = no
func load_specials(modifier: Modifier):
	tower.set_attack_style_bounce(5, 0.30)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.0375, _stats.mod_spell_crit_add)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_FROM_STORM, 0.0, 0.001)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://Resources/Icons/GenericIcons/over_infinity.tres")
	aura_bt.set_buff_tooltip("Realm of Thunder Aura\nIncreases damage taken from Storm towers.")

	
func get_aura_types() -> Array[AuraType]:
	var aura_level: int = int(_stats.mod_dmg_from_storm * 1000)
	var aura_level_add: int = int(_stats.mod_dmg_from_storm_add * 1000)

	var aura: AuraType = AuraType.new()

	var storm_string: String = Element.convert_to_colored_string(Element.enm.STORM)
	var mod_dmg_from_storm: String = Utils.format_percent(_stats.mod_dmg_from_storm, 2)
	var mod_dmg_from_storm_add: String = Utils.format_percent(_stats.mod_dmg_from_storm_add, 2)

	aura.name = "Realm of Thunder"
	aura.icon = "res://Resources/Icons/TowerIcons/LightningGenerator.tres"
	aura.description_short = "Increases the vulnerability of enemies in range to damage from %s towers.\n" % storm_string
	aura.description_full = "Increases the vulnerability of enemies in %d range to damage from %s towers by %s.\n" % [AURA_RANGE, storm_string, mod_dmg_from_storm] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s vulnerability\n" % mod_dmg_from_storm_add

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = true
	aura.level = aura_level
	aura.level_add = aura_level_add
	aura.power = aura_level
	aura.power_add = aura_level_add
	aura.aura_effect = aura_bt
	return [aura]


func on_damage(event: Event):
	var creep: Unit = event.get_target()
	var strike_chance: float = _stats.strike_chance + STRIKE_CHANCE_ADD * tower.get_level()
	var strike_damage: float = _stats.strike_damage + _stats.strike_damage_add * tower.get_level()

	if !tower.calc_chance(strike_chance):
		return

	CombatLog.log_ability(tower, creep, "Lightning Strike")

	tower.do_spell_damage(creep, strike_damage, tower.calc_spell_crit_no_bonus())
	SFX.sfx_on_unit("MonsoonBoltTarget.mdl", creep, Unit.BodyPart.ORIGIN)
