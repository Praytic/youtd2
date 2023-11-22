extends Tower


var drol_slow: BuffType
var drol_mortal_aura: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {cursed_attack_damage = 200, cursed_attack_damage_add = 10, mod_movespeed = 0.20, mod_spell_dmg_received = 0.100, aura_effect_value = 0.10, aura_effect_value_add = 0.004, aura_level = 0, aura_level_add = 2},
		2: {cursed_attack_damage = 320, cursed_attack_damage_add = 16, mod_movespeed = 0.25, mod_spell_dmg_received = 0.125, aura_effect_value = 0.15, aura_effect_value_add = 0.006, aura_level = 25, aura_level_add = 3},
		3: {cursed_attack_damage = 560, cursed_attack_damage_add = 28, mod_movespeed = 0.30, mod_spell_dmg_received = 0.150, aura_effect_value = 0.20, aura_effect_value_add = 0.008, aura_level = 50, aura_level_add = 4},
	}

const CURSED_ATTACK_CHANCE: float = 0.25
const CURSED_ATTACK_CHANCE_ADD: float = 0.01
const CURSED_DURATION: float = 4
const CURSED_DURATION_ADD: float = 0.1
const AURA_RANGE: float = 350


func get_ability_description() -> String:
	var cursed_attack_chance: String = Utils.format_percent(CURSED_ATTACK_CHANCE, 2)
	var cursed_attack_chance_add: String = Utils.format_percent(CURSED_ATTACK_CHANCE_ADD, 2)
	var cursed_attack_damage: String = Utils.format_float(_stats.cursed_attack_damage, 2)
	var cursed_attack_damage_add: String = Utils.format_float(_stats.cursed_attack_damage_add, 2)
	var cursed_duration: String = Utils.format_float(CURSED_DURATION, 2)
	var cursed_duration_add: String = Utils.format_float(CURSED_DURATION_ADD, 2)
	var mod_movespeed: String = Utils.format_percent(_stats.mod_movespeed, 2)
	var mod_spell_dmg_received: String = Utils.format_percent(_stats.mod_spell_dmg_received, 2)
	var aura_effect_value: String = Utils.format_percent(_stats.aura_effect_value, 2)
	var aura_effect_value_add: String = Utils.format_percent(_stats.aura_effect_value_add, 2)
	var aura_range: String = Utils.format_float(AURA_RANGE, 2)

	var text: String = ""

	text += "[color=GOLD]Cursed Attack[/color]\n"
	text += "This tower has a %s chance on damage to deal %s additional spell damage and weaken the target for %s seconds, reducing its movement speed by %s and make it suffer %s more damage from spells.\n" % [cursed_attack_chance, cursed_attack_damage, cursed_duration, mod_movespeed, mod_spell_dmg_received]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s chance\n" % cursed_attack_chance_add
	text += "+%s spell damage\n" % cursed_attack_damage_add
	text += "+%s sec slow duration\n" % cursed_duration_add
	text += " \n"
	text += "[color=GOLD]Mortal Coil - Aura[/color]\n"
	text += "Grants %s bonus damage against human, orc and nature creeps to all towers within %s range.\n" % [aura_effect_value, aura_range]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % aura_effect_value_add

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Cursed Attack[/color]\n"
	text += "This tower has a chance on damage to deal additional spell damage and weaken the target, reducing its movement speed and making it suffer more damage from spells.\n"
	text += " \n"
	text += "[color=GOLD]Mortal Coil - Aura[/color]\n"
	text += "Grants bonus damage against human, orc and nature creeps to nearby towers.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	_set_attack_style_bounce(4, 0.3)


func tower_init():
	drol_slow = BuffType.new("drol_slow", 0, 0, false, self)
	var drol_slow_mod: Modifier = Modifier.new()
	drol_slow_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	drol_slow_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.0, 0.0005)
	drol_slow.set_buff_modifier(drol_slow_mod)
	drol_slow.set_buff_icon("@@0@@")
	drol_slow.set_stacking_group("drol_slow1")
	drol_slow.set_buff_tooltip("Curse\nThis unit has been cursed; it has reduced movement speed and will take extra damage from spells.")

	drol_mortal_aura = BuffType.create_aura_effect_type("drol_mortal_aura", true, self)
	var drol_mortal_aura_mod: Modifier = Modifier.new()
	drol_mortal_aura_mod.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.1, 0.002)
	drol_mortal_aura_mod.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.1, 0.002)
	drol_mortal_aura_mod.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.1, 0.002)
	drol_mortal_aura.set_buff_modifier(drol_mortal_aura_mod)
	drol_mortal_aura.set_buff_icon("@@1@@")
	drol_mortal_aura.set_stacking_group("drol_mortal_aura")
	drol_mortal_aura.set_buff_tooltip("Mortal Coil Aura\nThis unit is under the effect of Mortal Coil Aura; it will deal extra damage against human, orc and nature creeps.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = _stats.aura_level
	aura.level_add = _stats.aura_level_add
	aura.power = _stats.aura_level
	aura.power_add = _stats.aura_level_add
	aura.aura_effect = drol_mortal_aura
	return [aura]


func on_damage(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()
	var level: int = tower.get_level()

	if !tower.calc_chance(CURSED_ATTACK_CHANCE + CURSED_ATTACK_CHANCE_ADD * level):
		return

	if !creep.is_immune():
		tower.do_spell_damage(creep, _stats.cursed_attack_damage + _stats.cursed_attack_damage_add * level, tower.calc_spell_crit_no_bonus())
		var buff_level: int = int(_stats.mod_movespeed * 1000)
		var buff_duration: float = CURSED_DURATION + CURSED_DURATION_ADD * level
		drol_slow.apply_custom_timed(tower, creep, buff_level, buff_duration)
		SFX.sfx_on_unit("feralspirittarget.mdl", creep, Unit.BodyPart.ORIGIN)
