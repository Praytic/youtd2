extends Tower


var prince_of_lightning_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_spell_crit_add = 0.0025, strike_chance = 0.15, strike_damage = 2000, strike_damage_add = 100, mod_dmg_from_storm = 0.10, mod_dmg_from_storm_add = 0.002},
		2: {mod_spell_crit_add = 0.0050, strike_chance = 0.20, strike_damage = 4000, strike_damage_add = 200, mod_dmg_from_storm = 0.15, mod_dmg_from_storm_add = 0.004},
	}

const STRIKE_CHANCE_ADD: float = 0.004
const AURA_RANGE: float = 1300


func get_ability_description() -> String:
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)
	var strike_chance: String = Utils.format_percent(_stats.strike_chance, 2)
	var strike_chance_add: String = Utils.format_percent(STRIKE_CHANCE_ADD, 2)
	var strike_damage: String = Utils.format_float(_stats.strike_damage, 2)
	var strike_damage_add: String = Utils.format_float(_stats.strike_damage_add, 2)
	var mod_dmg_from_storm: String = Utils.format_percent(_stats.mod_dmg_from_storm, 2)
	var mod_dmg_from_storm_add: String = Utils.format_percent(_stats.mod_dmg_from_storm_add, 2)

	var text: String = ""

	text += "[color=GOLD]Lightning Strike[/color]\n"
	text += "When this tower damages a target there is a %s chance that a lightning bolt strikes the target for %s damage. \n" % [strike_chance, strike_damage]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % strike_damage_add
	text += "+%s chance\n" % strike_chance_add
	text += " \n"
	text += "[color=GOLD]Realm of Thunder - Aura[/color]\n"
	text += "Increases the vulnerability of enemies in %s range to damage from Storm towers by %s. \n" % [aura_range, mod_dmg_from_storm]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s vulnerability\n" % mod_dmg_from_storm_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Lightning Strike[/color]\n"
	text += "When this tower damages a target there is a chance that a lightning bolt strikes the target.\n"
	text += " \n"
	text += "[color=GOLD]Realm of Thunder - Aura[/color]\n"
	text += "Makes nearby creeps more vulnerable to Storm towers.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


# NOTE: this tower's tooltip in original game includes
# innate stats in some cases
# spell crit chance = yes
# spell crit chance add = no
func load_specials(modifier: Modifier):
	_set_attack_style_bounce(5, 0.30)
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.0375, _stats.mod_spell_crit_add)


func tower_init():
	prince_of_lightning_bt = BuffType.create_aura_effect_type("prince_of_lightning_bt", false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_FROM_STORM, 0.0, 0.001)
	prince_of_lightning_bt.set_buff_modifier(mod)
	prince_of_lightning_bt.set_buff_icon("@@0@@")
	prince_of_lightning_bt.set_buff_tooltip("Real of Thunder Aura\nThis tower is under the effect of Realm of Thunder Aura; it takes extra damage from Storm towers.")

	
func get_aura_types() -> Array[AuraType]:
	var aura_level: int = int(_stats.mod_dmg_from_storm * 1000)
	var aura_level_add: int = int(_stats.mod_dmg_from_storm_add * 1000)

	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = true
	aura.level = aura_level
	aura.level_add = aura_level_add
	aura.power = aura_level
	aura.power_add = aura_level_add
	aura.aura_effect = prince_of_lightning_bt
	return [aura]


func on_damage(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()
	var strike_chance: float = _stats.strike_chance + STRIKE_CHANCE_ADD * tower.get_level()
	var strike_damage: float = _stats.strike_damage + _stats.strike_damage_add * tower.get_level()

	if !tower.calc_chance(strike_chance):
		return

	tower.do_spell_damage(creep, strike_damage, tower.calc_spell_crit_no_bonus())
	SFX.sfx_on_unit("MonsoonBoltTarget.mdl", creep, "origin")
