extends TowerBehavior


var strong_wind_bt: BuffType
var multiboard: MultiboardValues
var storm_power: int = 0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Strong Wind[/color]\n"
	text += "All creeps in 900 range are affected by Strong Winds. Every second a creep is under this effect, it loses 3% of its movespeed and it is dealt 10% of towers attack damage for every 1% of movespeed it is missing. Slow effect stacks up to 15 times. Slow effect and damage is doubled for air units.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.08% slow\n"
	text += "+5 damage per 1% slow\n"
	text += " \n"

	text += "[color=GOLD]Chaining Storm[/color]\n"
	text += "Whenever this tower attacks, it has a 25% chance to cast a Chaining Storm at the position of the attacked creep for the cost of 100 mana. All creeps in 350 range of the Chaining Storm suffer 200 spelldamage multiplied by the number of creeps hit. They are also weakened to receive 2% more damage from Storm, Ice and Astral Towers for each hitted creep. All effects of this ability are doubled and a 25% higher spell critical chance is applied whenever the main target hit is an air unit.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1.25% trigger chance\n"
	text += "+65 damage\n"
	text += "+0.12% received damage\n"
	text += " \n"

	text += "[color=GOLD]Storm Power - Aura[/color]\n"
	text += "If a creep dies while under the effect of Strong Wind its living energy is converted in +35 mana and boost this tower's abilities. Each death increases the triggerchance for Chaining Storm by +0.02% (maximum total triggerchance for Chaining Storm is 75%) and also increase the damage dealt with Strong Winds by 0.05 damage per 1% slow.\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Strong Wind[/color]\n"
	text += "All creeps in range are affected by Strong Winds. Creeps are slowed and will receive periodic damage.\n"
	text += " \n"

	text += "[color=GOLD]Chaining Storm[/color]\n"
	text += "Chance to cast a Chaining Storm at the position of the attacked creep. All creeps in range of the Chaining Storm suffer spelldamage.\n"
	text += " \n"

	text += "[color=GOLD]Storm Power - Aura[/color]\n"
	text += "If a creep dies while under the effect of Strong Wind its living energy is converted into mana and boosts this tower's abilities.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.50, 0.02)
	modifier.add_modification(Modification.Type.MOD_MANA, 15, 0)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, 0.1)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Strong Wind", 900, TargetType.new(TargetType.CREEPS))]


func tower_init():
	strong_wind_bt = BuffType.create_aura_effect_type("strong_wind_bt", false, self)
	strong_wind_bt.set_buff_icon("res://Resources/Textures/Buffs/electricity.tres")
	strong_wind_bt.add_event_on_create(strong_wind_bt_on_create)
	strong_wind_bt.add_periodic_event(strong_wind_bt_periodic, 1.0)
	strong_wind_bt.add_event_on_cleanup(strong_wind_bt_on_cleanup)
	strong_wind_bt.set_buff_tooltip("Strong Wind\nReduces movement speed and deals damage over time.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Storm Power")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 900
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
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
	var effect1: int = Effect.create_simple("ThunderClapCaster.mdl", Vector2(x, y))
	Effect.destroy_effect_after_its_over(effect1)
	var effect2: int = Effect.create_simple("CycloneTarget.mdl", Vector2(x, y))
	Effect.destroy_effect_after_its_over(effect2)
	var effect3: int = Effect.create_simple("ManaDrainTarget.mdl", Vector2(x, y))
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
