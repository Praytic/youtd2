extends Tower


var red_ball_lightning_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {bounce_count = 2, shock_damage = 1200, shock_damage_add = 48, mod_spell_damage = 0.20, mod_spell_damage_add = 0.004},
		2: {bounce_count = 3, shock_damage = 3500, shock_damage_add = 140, mod_spell_damage = 0.35, mod_spell_damage_add = 0.006},
	}

const AURA_RANGE: float = 250
const SHOCK_CHANCE: float = 0.30
const SHOCK_CHANCE_ADD: float = 0.005
const SHOCK_CRIT_CHANCE: float = 0.10
const SHOCK_CRIT_DAMAGE: float = 0.60


func get_ability_description() -> String:
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)
	var shock_chance: String = Utils.format_percent(SHOCK_CHANCE, 2)
	var shock_chance_add: String = Utils.format_percent(SHOCK_CHANCE_ADD, 2)
	var shock_damage: String = Utils.format_float(_stats.shock_damage, 2)
	var shock_damage_add: String = Utils.format_float(_stats.shock_damage_add, 2)
	var shock_crit_chance: String = Utils.format_percent(SHOCK_CRIT_CHANCE, 2)
	var shock_crit_damage: String = Utils.format_percent(SHOCK_CRIT_DAMAGE, 2)
	var mod_spell_damage: String = Utils.format_percent(_stats.mod_spell_damage, 2)
	var mod_spell_damage_add: String = Utils.format_percent(_stats.mod_spell_damage_add, 2)

	var text: String = ""

	text += "[color=GOLD]Lightning Shock[/color]\n"
	text += "This tower has a %s chance to deal %s spell damage to its target, whenever it deals damage. This ability has a %s bonus chance to crit with %s bonus damage.\n" % [shock_chance, shock_damage, shock_crit_chance, shock_crit_damage]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s chance\n" % shock_chance_add
	text += "+%s damage\n" % shock_damage_add
	text += " \n"
	text += "[color=GOLD]Lightning Charge - Aura[/color]\n"
	text += "Towers in %s range have their spell damage increased by %s.\n" % [aura_range, mod_spell_damage]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spell damage\n" % mod_spell_damage_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Lightning Shock[/color]\n"
	text += "This tower has a chance to release a lightning shock when attacking.\n"
	text += " \n"
	text += "[color=GOLD]Lightning Charge - Aura[/color]\n"
	text += "Increases spell damage of nearby towers.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	_set_attack_style_bounce(_stats.bounce_count, 0.60)


func tower_init():
	red_ball_lightning_bt = BuffType.create_aura_effect_type("red_ball_lightning_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.0, 0.0001)
	red_ball_lightning_bt.set_buff_modifier(mod)
	red_ball_lightning_bt.set_buff_icon("@@0@@")
	red_ball_lightning_bt.set_buff_tooltip("Lightning Charge Aura\nThis tower is under the effect of Lightning Charge Aura; it deals extra spell damage.")

	var aura_level: int = int(_stats.mod_spell_damage * 10000)
	var aura_level_add: int = int(_stats.mod_spell_damage_add * 10000)

	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = aura_level
	aura.level_add = aura_level_add
	aura.power = aura_level
	aura.power_add = aura_level_add
	aura.aura_effect = red_ball_lightning_bt
	add_aura(aura)


func on_damage(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()
	var shock_chance: float = SHOCK_CHANCE + SHOCK_CHANCE_ADD * tower.get_level()
	var shock_damage: float = _stats.shock_damage + _stats.shock_damage_add * tower.get_level()
	var shock_crit_ratio: float = tower.calc_spell_crit(0.1, 0.6)

	if !tower.calc_chance(shock_chance):
		return

	var lightning: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, tower, creep)
	lightning.modulate = Color.RED
	lightning.set_lifetime(0.2)

	tower.do_spell_damage(creep, shock_damage, shock_crit_ratio)
