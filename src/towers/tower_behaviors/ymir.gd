extends TowerBehavior


var multiboard: MultiboardValues
var blood_bt: BuffType
var aura_bt: BuffType
var wrath_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 900, TargetType.new(TargetType.CREEPS))


func tower_init():
	blood_bt = BuffType.new("blood_bt", 6.0, 0.08, false, self)
	var iaman_ymir_blood_mod: Modifier = Modifier.new()
	iaman_ymir_blood_mod.add_modification(Modification.Type.MOD_DMG_FROM_ICE, 0.25, 0.004)
	blood_bt.set_buff_modifier(iaman_ymir_blood_mod)
	blood_bt.set_buff_icon("res://resources/icons/generic_icons/round_potion.tres")
	blood_bt.set_buff_tooltip(tr("MR2Y"))

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var iaman_ymir_flesh_mod: Modifier = Modifier.new()
	iaman_ymir_flesh_mod.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.25, -0.006)
	aura_bt.set_buff_modifier(iaman_ymir_flesh_mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/meat.tres")
	aura_bt.set_buff_tooltip(tr("LJ28"))

	wrath_bt = BuffType.new("wrath_bt", 0, 0, false, self)
	var iaman_ymir_wrath_mod: Modifier = Modifier.new()
	iaman_ymir_wrath_mod.add_modification(Modification.Type.MOD_MOVESPEED, -1.0, 0.001)
	wrath_bt.set_buff_modifier(iaman_ymir_wrath_mod)
	wrath_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	wrath_bt.set_buff_tooltip(tr("SCJ8"))

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Wrath Spelldamage")


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
	Effect.create_simple_at_unit("res://src/effects/ziggurat_frost_missile.tscn", target)


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
