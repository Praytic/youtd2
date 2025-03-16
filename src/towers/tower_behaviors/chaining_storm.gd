extends TowerBehavior


var strong_wind_bt: BuffType
var multiboard: MultiboardValues
var storm_power: int = 0


const AURA_RANGE: int = 900


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var storm_string: String = Element.convert_to_colored_string(Element.enm.STORM)
	var ice_string: String = Element.convert_to_colored_string(Element.enm.ICE)
	var astral_string: String = Element.convert_to_colored_string(Element.enm.ASTRAL)

	var list: Array[AbilityInfo] = []
	
	var storm_power_ability: AbilityInfo = AbilityInfo.new()
	storm_power_ability.name = "Storm Power"
	storm_power_ability.icon = "res://resources/icons/tower_icons/lightning_generator.tres"
	storm_power_ability.description_short = "If a creep dies while under the effect of [color=GOLD]Strong Wind[/color] its living energy is converted into mana and boosts this tower's abilities.\n"
	storm_power_ability.description_full = "If a creep dies while under the effect of [color=GOLD]Strong Wind[/color] its living energy is converted in +35 mana and boost this tower's abilities. Each death increases the triggerchance for this [color=GOLD]Chaining Storm[/color] tower by 0.02% (75% max) and also increase the damage dealt with [color=GOLD]Strong Winds[/color] by 0.05 damage per 1% slow.\n"
	list.append(storm_power_ability)

	var chaining_storm: AbilityInfo = AbilityInfo.new()
	chaining_storm.name = "Chaining Storm"
	chaining_storm.icon = "res://resources/icons/electricity/thunderstorm.tres"
	chaining_storm.description_short = "Chance to cast [color=GOLD]Chaining Storm[/color] at the attacked creep. All creeps in range of the [color=GOLD]Chaining Storm[/color] suffer spell damage.\n"
	chaining_storm.description_full = "25%% chance to cast [color=GOLD]Chaining Storm[/color] at the attacked creep for the cost of 100 mana. All creeps in 350 range of the [color=GOLD]Chaining Storm[/color] suffer 200 spell damage multiplied by the number of creeps hit. They are also weakened to receive [color=GOLD][2 x creep count]%%[/color] more damage from %s, %s and %s towers. All effects of this [color=GOLD]Chaining Storm[/color] tower are doubled and a 25%% higher spell critical chance is applied whenever the main target is an air unit.\n" % [storm_string, ice_string, astral_string] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1.25% trigger chance\n" \
	+ "+65 damage\n" \
	+ "+0.12% received damage\n"
	list.append(chaining_storm)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.50, 0.02)
	modifier.add_modification(Modification.Type.MOD_MANA, 0, 15)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, 0.1)


func tower_init():
	strong_wind_bt = BuffType.create_aura_effect_type("strong_wind_bt", false, self)
	strong_wind_bt.set_buff_icon("res://resources/icons/generic_icons/energy_breath.tres")
	strong_wind_bt.add_event_on_create(strong_wind_bt_on_create)
	strong_wind_bt.add_periodic_event(strong_wind_bt_periodic, 1.0)
	strong_wind_bt.add_event_on_cleanup(strong_wind_bt_on_cleanup)
	strong_wind_bt.set_buff_tooltip("Strong Wind\nReduces movement speed and deals damage over time.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Storm Power")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Strong Wind"
	aura.icon = "res://resources/icons/electricity/lightning_circle_cyan.tres"
	aura.description_short = "All creeps in range are affected by [color=GOLD]Strong Winds[/color]. Creeps are slowed and will receive periodic damage.\n"
	aura.description_full = "All creeps in %d range are affected by [color=GOLD]Strong Winds[/color]. Every second a creep is under this effect, it loses 3%% of its movement speed and it is dealt 10%% of towers attack damage for every 1%% of movement speed it is missing. Slow effect stacks up to 15 times. Slow effect and damage is doubled for air units.\n" % AURA_RANGE \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.08% slow\n" \
	+ "+5 damage per 1% slow\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = strong_wind_bt

	return [aura]


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var lvl: int = tower.get_level()
	var x: float = target.get_x()
	var y: float = target.get_y()
	var bonus_spell_crit: float = 0.0
	var air_bonus: float = 1.0

	var chaining_storm_chance: float = 0.25 + 0.0125 * lvl + 0.0002 * storm_power

	if !tower.calc_chance(chaining_storm_chance):
		return

	if tower.get_mana() < 100:
		return

	tower.subtract_mana(100, false)

#	remove Mana
#	First Iteration
#	for damage -> count creeps (save in: numCreeps)

	CombatLog.log_ability(tower, target, "Chaining Storm")

	var it_for_count: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 350)
	var creep_count: int = it_for_count.count()

#	do effects
	Effect.create_simple("res://src/effects/thunder_clap.tscn", Vector2(x, y))
	Effect.create_simple("res://src/effects/cyclone_target.tscn", Vector2(x, y))
	var effect3: int = Effect.create_simple("res://src/effects/voodoo_aura.tscn", Vector2(x, y))
	Effect.set_z_index(effect3, Effect.Z_INDEX_BELOW_CREEPS)
	Effect.set_lifetime(effect3, 1.0)

# 	Adjust ratios against air
	if target.get_size() == CreepSize.enm.AIR:
		bonus_spell_crit = 0.25
		air_bonus = 2.0

	var damage: float = creep_count * air_bonus * (200 + 65 * lvl)
	tower.do_spell_damage_aoe_unit(target, 350, damage, tower.calc_spell_crit_no_bonus() + bonus_spell_crit, 0)

#	weaken creeps (weakening is divided by the number of creeps hit)
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 350)
	var mod: float = (0.02 * 0.0012 * lvl) * creep_count
	
	while true:
		var next: Unit = it.next()

		if next == null:
			break

		next.modify_property(Modification.Type.MOD_DMG_FROM_STORM, mod)
		next.modify_property(Modification.Type.MOD_DMG_FROM_ICE, mod)
		next.modify_property(Modification.Type.MOD_DMG_FROM_ASTRAL, mod)


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, str(storm_power))

	return multiboard


# NOTE: "strongWindOnCreate()" in original script
func strong_wind_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	buff.user_int = 0 # will be used to store buff level
	buff.user_int2 = 0 # counts number of stacks
	buff.user_real = 0.0 # records movespeed stolen (in case aura has levelled)
	buff.user_real2 = 0.03 # stores slow factor, so that we don't need to recalculate it every second


# NOTE: "strongWindPeriodic()" in original script
func strong_wind_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var creep: Unit = buff.get_buffed_unit()
	var buff_level: int = buff.get_level()

#	Check if aura level hasn't changed
	if buff_level != buff.user_int:
		buff.user_int = buff_level

#		Give creep back its old movespeed and calculate new slow factor
		buff.user_real2 = 0.03 + 0.0008 * buff_level

		if creep.get_size() == CreepSize.enm.AIR:
			buff.user_real2 *= 2

#		Adjust movespeed accordingly
		creep.modify_property(Modification.Type.MOD_MOVESPEED, buff.user_real - buff.user_real2 * buff.user_int2)
		buff.user_real = buff.user_real2 * buff.user_int2

#	Apply slow
	if buff.user_int2 < 15:	# Max 15 stacks
		buff.user_int2 += 1
		creep.modify_property(Modification.Type.MOD_MOVESPEED, -buff.user_real2)
		buff.user_real = buff.user_real + buff.user_real2

	buff.set_displayed_stacks(buff.user_int2)

#	Deal damage
	var damage_multiplier: float = 1.0 + 0.05 * buff_level + 0.0005 * storm_power
	var damage: float = buff.user_real * 10 * caster.get_current_attack_damage_with_bonus() * damage_multiplier
	caster.do_attack_damage(creep, damage, caster.calc_attack_multicrit_no_bonus())


# NOTE: "strongWindOnCleanup()" in original script
func strong_wind_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var creep: Unit = buff.get_buffed_unit()

	if creep.get_health() > 0:
#		Give creep its movespeed back
		creep.modify_property(Modification.Type.MOD_MOVESPEED, buff.user_real)
	else:
#		creep died under the effect? Increse storm power!
		storm_power += 1
#		+ mana
		caster.add_mana(35)
