extends TowerBehavior


var dps_boost_bt: BuffType
var slow_bt: BuffType
var multiboard: MultiboardValues

var current_attack_target: int = -1
var current_attack_count: int = -1
var strangle_count: int = 0


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var fishermans_net: AbilityInfo = AbilityInfo.new()
	fishermans_net.name = "Fisherman's Net"
	fishermans_net.icon = "res://resources/icons/food/lard.tres"
	fishermans_net.description_short = "Whenever this tower hits a creep, it catches the creep in its net, slowing them.\n"
	fishermans_net.description_full = "Whenever this tower hits a creep, it catches the creep in its net, slowing them by 25% for 3 seconds. If a creep's movement speed is below 120 when this buff expires, it will have failed to free itself and will have a 3% chance of getting strangled in the net and dying. Bosses and immune units receive 400% attack damage from this tower instead of death. The chance to die is adjusted by how long the creep was ensnared: the longer the buff duration, the greater the chance and vice versa. Stunned creeps will also trigger the instant kill chance.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% slow\n" \
	+ "+2.4 movement speed required\n" \
	+ "+0.2% chance\n"
	list.append(fishermans_net)

	var fresh_fish_ability: AbilityInfo = AbilityInfo.new()
	fresh_fish_ability.name = "Fresh Fish!"
	fresh_fish_ability.icon = "res://resources/icons/animals/fish_01.tres"
	fresh_fish_ability.description_short = "Each time [color=GOLD]Fisherman's Net[/color] strangles a creep, it increases the DPS of nearby towers.\n"
	fresh_fish_ability.description_full = "Each time [color=GOLD]Fisherman's Net[/color] strangles a creep, the DPS of towers in 500 range is increased by 15% of this tower's DPS for 5 seconds.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.1 second duration\n" \
	+ "+0.004 damage per second multipler\n"
	list.append(fresh_fish_ability)

	var impatient: AbilityInfo = AbilityInfo.new()
	impatient.name = "Impatient"
	impatient.icon = "res://resources/icons/daggers/dagger_06.tres"
	impatient.description_short = "After 4 attacks on the same target the fisherman will attack a different unit.\n"
	impatient.description_full = "After 4 attacks on the same target the fisherman will attack a different unit. Favoring creeps that are not suffering the effect of [color=GOLD]Fisherman's Net[/color].\n"
	list.append(impatient)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.08)


func tower_init():
	dps_boost_bt = BuffType.new("dps_boost_bt", 0, 0, true, self)
	var fisherman_dps_boost_mod: Modifier = Modifier.new()
	fisherman_dps_boost_mod.add_modification(Modification.Type.MOD_DPS_ADD, 0.0, 0.001)
	dps_boost_bt.set_buff_modifier(fisherman_dps_boost_mod)
	dps_boost_bt.set_buff_icon("res://resources/icons/GenericIcons/meat.tres")
	dps_boost_bt.set_buff_tooltip("Fresh Fish!\nIncreases DPS.")

	slow_bt = BuffType.new("slow_bt", 3, 0, false, self)
	var fisherman_slow_mod: Modifier = Modifier.new()
	fisherman_slow_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.25, -0.01)
	slow_bt.set_buff_modifier(fisherman_slow_mod)
	slow_bt.set_buff_icon("res://resources/icons/GenericIcons/foot_trip.tres")
	slow_bt.add_event_on_create(slow_bt_on_create)
	slow_bt.add_event_on_expire(slow_bt_on_expire)
	slow_bt.set_buff_tooltip("Strangled\nReduces movement speed.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Strangled Units")


func on_attack(event: Event):
	var target: Unit = event.get_target()

	if current_attack_target != target.get_instance_id():
		current_attack_target = target.get_instance_id()
		current_attack_count = 0

	current_attack_count += 1

	var impatient_procced: bool = current_attack_count > 4 && target.get_size() < CreepSize.enm.BOSS

	if !impatient_procced:
		return

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), tower.get_range())

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		if next != target && next.get_buff_of_type(slow_bt) == null:
			CombatLog.log_ability(tower, next, "Impatient")
			tower.issue_target_order(next)

			return

	current_attack_count = 0


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	slow_bt.apply(tower, target, level)


func on_tower_details() -> MultiboardValues:
	var strangle_count_string: String = str(strangle_count)
	multiboard.set_value(0, strangle_count_string)

	return multiboard


func slow_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var net_start_time: float = Utils.get_time()
	buff.user_real = net_start_time


func slow_bt_on_expire(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var lvl: int = tower.get_level()
	var movespeed_for_strangle: float = 120 + 2.4 * lvl
	var net_start_time: float = buff.user_real
	var net_duration: float = Utils.get_time() - net_start_time
	var target_can_be_strangled: bool = target.get_current_movespeed() <= movespeed_for_strangle || target.is_stunned()
	var strangle_chance: float = (0.03 + 0.002 * lvl) * (net_duration / 3.0)
	var damage_for_boss: float = tower.get_current_attack_damage_with_bonus() * (4 + 0.16 * lvl)
	var strangle_procced: bool = target_can_be_strangled && tower.calc_chance(strangle_chance)

	if !strangle_procced:
		return

	if target.get_size() >= CreepSize.enm.BOSS || target.is_immune():
		CombatLog.log_ability(tower, target, "Strangle boss damage")
		tower.do_attack_damage(target, damage_for_boss, tower.calc_attack_multicrit_no_bonus())
	else:
		CombatLog.log_ability(tower, target, "Strangle non-boss instant kill")
		tower.kill_instantly(target)

	fresh_fish()
	SFX.sfx_on_unit("HumanLargeDeathExplode.mdl", target, Unit.BodyPart.ORIGIN)
	strangle_count += 1


func fresh_fish():
	var buff_level: int = int(1000 * tower.get_current_attack_damage_with_bonus() / tower.get_current_attack_speed() * (0.15 + 0.004 * tower.get_level()))
	var duration: float = 5.0 + 0.1 * tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		dps_boost_bt.apply_custom_timed(tower, next, buff_level, duration)
