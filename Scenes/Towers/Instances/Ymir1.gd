extends Tower


var multiboard: MultiboardValues
var iaman_ymir_blood_bt: BuffType
var iaman_ymir_flesh_bt: BuffType
var iaman_ymir_wrath_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Wrath of Ymir[/color]\n"
	text += "When Ymir damages a creep, there is a 20% chance that he deals an additional 10% of his attack damage as spell damage and slows the target by an amount equal to the percent of its remaining hitpoints for 2 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% chance\n"
	text += "+0.6% damage\n"
	text += " \n"

	text += "[color=GOLD]Blood of Ymir[/color]\n"
	text += "When a creep comes in 900 range of Ymir, he debuffs the creep for 6 seconds, increasing vulnerability to Ice towers by 25%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.08 seconds duration\n"
	text += "+0.4% vulnerability\n"
	text += " \n"

	text += "[color=GOLD]Flesh of Ymir - Aura[/color]\n"
	text += "The ancient Flesh of Ymir grants him -25% debuff duration.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-0.6% debuff duration\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Wrath of Ymir[/color]\n"
	text += "Chance to deal portion of attack damage as spell damage and slow the target.\n"
	text += " \n"

	text += "[color=GOLD]Blood of Ymir[/color]\n"
	text += "Increasing vulnerability to Ice towers of creeps which come in range.\n"
	text += " \n"

	text += "[color=GOLD]Flesh of Ymir - Aura[/color]\n"
	text += "The ancient Flesh of Ymir grants him reduced debuff duration.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 900, TargetType.new(TargetType.CREEPS))


func load_specials(modifier: Modifier):
	set_attack_style_splash({400: 0.25})
	modifier.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.10)


func tower_init():
	iaman_ymir_blood_bt = BuffType.new("iaman_ymir_blood_bt", 6.0, 0.08, false, self)
	var iaman_ymir_blood_mod: Modifier = Modifier.new()
	iaman_ymir_blood_mod.add_modification(Modification.Type.MOD_DMG_FROM_ICE, 0.25, 0.004)
	iaman_ymir_blood_bt.set_buff_modifier(iaman_ymir_blood_mod)
	iaman_ymir_blood_bt.set_buff_icon("@@0@@")
	iaman_ymir_blood_bt.set_buff_tooltip("Blood of Ymir\nThis unit is affected by Blood of Ymir; it wil take extra damage from Ice towers.")

	iaman_ymir_flesh_bt = BuffType.create_aura_effect_type("iaman_ymir_flesh_bt", true, self)
	var iaman_ymir_flesh_mod: Modifier = Modifier.new()
	iaman_ymir_flesh_mod.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.25, -0.006)
	iaman_ymir_flesh_bt.set_buff_modifier(iaman_ymir_flesh_mod)
	iaman_ymir_flesh_bt.set_buff_icon("@@1@@")
	iaman_ymir_flesh_bt.set_buff_tooltip("Flesh of Ymir Aura\nThis tower is under the effect of Flesh of Ymir Aura; it has reduced debuff duration.")

	iaman_ymir_wrath_bt = BuffType.new("iaman_ymir_wrath_bt", 0, 0, false, self)
	var iaman_ymir_wrath_mod: Modifier = Modifier.new()
	iaman_ymir_wrath_mod.add_modification(Modification.Type.MOD_MOVESPEED, -1.0, 0.001)
	iaman_ymir_wrath_bt.set_buff_modifier(iaman_ymir_wrath_mod)
	iaman_ymir_wrath_bt.set_buff_icon("@@2@@")
	iaman_ymir_wrath_bt.set_buff_tooltip("Wrath of Ymir\nThis unit is affected by Wrath of Ymir; it has reduced movement speed.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Wrath Spelldamage")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 0
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = iaman_ymir_flesh_bt

	return [aura]


func on_damage(event: Event):
	var tower: Tower = self
	var target: Creep = event.get_target()
	var wrath_chance: float = 0.20 + 0.004 * tower.get_level()

	if !tower.calc_chance(wrath_chance):
		return

	CombatLog.log_ability(tower, target, "Wrath of Ymir")

#	slow becomes less powerful with every cast
	var slow_power: int = 1000 - int(target.get_health_ratio() * 1000)
	var wrath_damage: float = get_wrath_damage()

	tower.do_spell_damage(target, wrath_damage, tower.calc_spell_crit_no_bonus())
	iaman_ymir_wrath_bt.apply_custom_timed(tower, target, slow_power, 2.0)
	SFX.sfx_at_unit("ZigguratFrostMissile.mdl", target)


func on_tower_details() -> MultiboardValues:
	var wrath_damage: float = get_wrath_damage()
	var wrath_damage_string: String = Utils.format_float(wrath_damage, 0)
	multiboard.set_value(0, wrath_damage_string)

	return multiboard


func on_unit_in_range(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	iaman_ymir_blood_bt.apply(tower, target, tower.get_level())


func get_wrath_damage() -> float:
	var tower: Tower = self
	var wrath_damage: float = tower.get_current_attack_damage_with_bonus() * (0.10 + 0.006 * tower.get_level())

	return wrath_damage
