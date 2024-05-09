extends TowerBehavior


# NOTE: original script has a bug where slow debuff is
# applied to the main target instead of all damaged units.
# Fixed it.


var slow_bt: BuffType
var aura_bt: BuffType
var seconds_since_last_attack: int = 0
var dmg_bonus_from_meld: float = 0.0


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var wrath: AbilityInfo = AbilityInfo.new()
	wrath.name = "Protectress's Wrath"
	wrath.icon = "res://Resources/Icons/plants/leaf_01.tres"
	wrath.description_short = "Each attack has a chance to deal an extra damage to all units in range around the target. Slows all damaged units.\n"
	wrath.description_full = "Each attack has a [seconds since last attack x 5]% chance to deal an extra 50% attack damage to all units in 250 range around the target. The maximum chance is 75%. Slows all damaged units by 50% for 1.5 seconds. Increased attackspeed decreases time needed to gain a charge.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+2% damage\n" \
	+ "+0.04 seconds\n"
	list.append(wrath)

	var meld: AbilityInfo = AbilityInfo.new()
	meld.name = "Meld with the Forest"
	meld.icon = "res://Resources/Icons/faces/sleeping_leaf_spirit.tres"
	meld.description_short = "The Protectress gains additional attack damage for each second she doesn't attack.\n"
	meld.description_full = "The Protectress gains 18% additional attack damage for each second she doesn't attack. There is a maximum of 12 seconds. On attack the bonus disappears. Increased attackspeed decreases the time needed to gain a charge.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% damage per second\n"
	list.append(meld)

	var strike: AbilityInfo = AbilityInfo.new()
	strike.name = "Strike the Unprepared - Aura"
	strike.icon = "res://Resources/Icons/daggers/dagger_07.tres"
	strike.description_short = "Increases the attack critical chance of towers in range based on hp of attacked creeps.\n"
	strike.description_full = "Increases the attack critical chance of towers in 175 range by 0.25% for each 1% hp the attacked creep has left.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.01% attack crit chance\n"
	list.append(strike)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 1.0)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.06)


func tower_init():
	slow_bt = BuffType.new("slow_bt", 1.5, 0.04, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.50, 0.0)
	slow_bt.set_buff_modifier(mod)
	slow_bt.set_buff_icon("res://Resources/Icons/GenericIcons/foot_trip.tres")
	slow_bt.set_buff_tooltip("Protectress's Wrath\nReduces movement speed.")

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://Resources/Icons/GenericIcons/hammer_drop.tres")
	aura_bt.add_event_on_attack(aura_bt_on_attack)
	aura_bt.add_event_on_cleanup(aura_bt_on_cleanup)
	aura_bt.set_buff_tooltip("Strike the Unprepared Aura\nIncreases crit chance based on target's health.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 175
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = aura_bt

	return [aura]


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var wrath_damage: float = (0.5 + 0.02 * tower.get_level()) * tower.get_current_attack_damage_with_bonus()
	var wrath_chance: float = 0.05 * seconds_since_last_attack

	if !tower.calc_chance(wrath_chance):
		return

	CombatLog.log_ability(tower, target, "Protectress's Wrath")

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 250)
	SFX.sfx_at_unit("NECancelDeath.mdl", target)
	tower.do_attack_damage_aoe_unit(target, 250, wrath_damage, tower.calc_attack_multicrit_no_bonus(), 0.0)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		slow_bt.apply(tower, next, tower.get_level())

	tower.set_sprite_color(Color.WHITE)
	tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, -dmg_bonus_from_meld)
	dmg_bonus_from_meld = 0.0
	seconds_since_last_attack = 0


func periodic(event: Event):
	var bonus_add: float = 0.18 + 0.01 * tower.get_level()
	var updated_period: float = tower.get_current_attackspeed() / 2.2

	if seconds_since_last_attack < 12:
		seconds_since_last_attack += 1

#		NOTE: original script uses alpha of (255 - 15 * seconds_since_last_attack).
#		Changed it to 7 because tower sprite was getting too
#		transparent.
		tower.set_sprite_color(Color8(255, 255, 255, 255 - 7 * seconds_since_last_attack))
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, bonus_add)
		dmg_bonus_from_meld += bonus_add

	event.enable_advanced(updated_period, false)


func aura_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Unit = buff.get_buffed_unit()
	var creep: Unit = event.get_target()
	var caster: Unit = buff.get_caster()
	var prev_bonus: float = buff.user_real
	var new_bonus: float = creep.get_health_ratio() * (0.25 + 0.01 * caster.get_level())

	buffed_tower.modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, -prev_bonus)
	buffed_tower.modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, new_bonus)

	buff.user_real = new_bonus


func aura_bt_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_tower: Unit = buff.get_buffed_unit()
	var applied_bonus: float = buff.user_real
	buffed_tower.modify_property(Modification.Type.MOD_ATK_CRIT_CHANCE, -applied_bonus)
