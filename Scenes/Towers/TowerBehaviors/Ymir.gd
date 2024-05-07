extends TowerBehavior


var multiboard: MultiboardValues
var blood_bt: BuffType
var aura_bt: BuffType
var wrath_bt: BuffType


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var wrath: AbilityInfo = AbilityInfo.new()
	wrath.name = "Wrath of Ymir"
	wrath.description_short = "Chance to deal portion of attack damage as spell damage and slow the target.\n"
	wrath.description_full = "When Ymir damages a creep, there is a 20% chance that he deals an additional 10% of his attack damage as spell damage and slows the target by an amount equal to the percent of its remaining hitpoints for 2 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% chance\n" \
	+ "+0.6% damage\n"
	list.append(wrath)

	var blood: AbilityInfo = AbilityInfo.new()
	blood.name = "Blood of Ymir"
	blood.description_short = "Creeps that come into range of Ymir temporarily take extra damage from Ice towers."
	blood.description_full = "When a creep comes in 900 range of Ymir, he debuffs the creep for 6 seconds, increasing vulnerability to Ice towers by 25%.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.08 seconds duration\n" \
	+ "+0.4% vulnerability\n"
	list.append(blood)

	var flesh: AbilityInfo = AbilityInfo.new()
	flesh.name = "Flesh of Ymir - Aura"
	flesh.description_short = "The ancient Flesh of Ymir grants him reduced debuff duration.\n"
	flesh.description_full = "The ancient Flesh of Ymir grants him -25% debuff duration.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "-0.6% debuff duration\n"
	list.append(flesh)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 900, TargetType.new(TargetType.CREEPS))


func load_specials(modifier: Modifier):
	tower.set_attack_style_splash({400: 0.25})
	modifier.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.10)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Blood of Ymir", 900, TargetType.new(TargetType.CREEPS))]


func tower_init():
	blood_bt = BuffType.new("blood_bt", 6.0, 0.08, false, self)
	var iaman_ymir_blood_mod: Modifier = Modifier.new()
	iaman_ymir_blood_mod.add_modification(Modification.Type.MOD_DMG_FROM_ICE, 0.25, 0.004)
	blood_bt.set_buff_modifier(iaman_ymir_blood_mod)
	blood_bt.set_buff_icon("res://Resources/Textures/GenericIcons/round_potion.tres")
	blood_bt.set_buff_tooltip("Blood of Ymir\nIncreases damage taken from Ice towers.")

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var iaman_ymir_flesh_mod: Modifier = Modifier.new()
	iaman_ymir_flesh_mod.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.25, -0.006)
	aura_bt.set_buff_modifier(iaman_ymir_flesh_mod)
	aura_bt.set_buff_icon("res://Resources/Textures/GenericIcons/meat.tres")
	aura_bt.set_buff_tooltip("Flesh of Ymir Aura\nReduces debuff duration.")

	wrath_bt = BuffType.new("wrath_bt", 0, 0, false, self)
	var iaman_ymir_wrath_mod: Modifier = Modifier.new()
	iaman_ymir_wrath_mod.add_modification(Modification.Type.MOD_MOVESPEED, -1.0, 0.001)
	wrath_bt.set_buff_modifier(iaman_ymir_wrath_mod)
	wrath_bt.set_buff_icon("res://Resources/Textures/GenericIcons/foot_trip.tres")
	wrath_bt.set_buff_tooltip("Wrath of Ymir\nReduces movement speed.")

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
	aura.aura_effect = aura_bt

	return [aura]


func on_damage(event: Event):
	var target: Creep = event.get_target()
	var wrath_chance: float = 0.20 + 0.004 * tower.get_level()

	if !tower.calc_chance(wrath_chance):
		return

	CombatLog.log_ability(tower, target, "Wrath of Ymir")

#	slow becomes less powerful with every cast
	var slow_power: int = 1000 - int(target.get_health_ratio() * 1000)
	var wrath_damage: float = get_wrath_damage()

	tower.do_spell_damage(target, wrath_damage, tower.calc_spell_crit_no_bonus())
	wrath_bt.apply_custom_timed(tower, target, slow_power, 2.0)
	SFX.sfx_at_unit("ZigguratFrostMissile.mdl", target)


func on_tower_details() -> MultiboardValues:
	var wrath_damage: float = get_wrath_damage()
	var wrath_damage_string: String = Utils.format_float(wrath_damage, 0)
	multiboard.set_value(0, wrath_damage_string)

	return multiboard


func on_unit_in_range(event: Event):
	var target: Unit = event.get_target()
	blood_bt.apply(tower, target, tower.get_level())


func get_wrath_damage() -> float:
	var wrath_damage: float = tower.get_current_attack_damage_with_bonus() * (0.10 + 0.006 * tower.get_level())

	return wrath_damage
