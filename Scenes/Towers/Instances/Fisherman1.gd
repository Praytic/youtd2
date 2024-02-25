extends Tower


var fisherman_dps_boost_bt: BuffType
var fisherman_slow_bt: BuffType
var multiboard: MultiboardValues

var current_attack_target: int = -1
var current_attack_count: int = -1
var strangle_count: int = 0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Fresh Fish![/color]\n"
	text += "Each time Fisherman's Net strangles a creep, the dps of towers in 500 range is increased by 15% of this tower's dps for 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.1 second duration\n"
	text += "+0.004 damage per second multipler\n"
	text += " \n"

	text += "[color=GOLD]Impatient[/color]\n"
	text += "After 4 attacks on the same target the fisherman will attack a different unit. Favoring creeps that are not suffering the effect of 'Fisherman's Net'.\n"
	text += " \n"

	text += "[color=GOLD]Fisherman's Net[/color]\n"
	text += "Creeps damaged by this tower get caught in its net, slowing them by 25% for 3 seconds. If a creep's movement speed is below 120 when this buff expires, it will have failed to free itself and will have a 3% chance of getting strangled in the net and dying. Bosses and immune units receive 400% attack damage from this tower instead of death. The chance to die is adjusted by how long the creep was ensnared: the longer the buff duration, the greater the chance and vice versa. Stunned creeps will also trigger the instant kill chance.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% slow\n"
	text += "+2.4 movement speed required\n"
	text += "+0.2% chance\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Fresh Fish![/color]\n"
	text += "Each time Fisherman's Net strangles a creep, it increases the dps of nearby towers.\n"
	text += " \n"

	text += "[color=GOLD]Impatient[/color]\n"
	text += "After 4 attacks on the same target the fisherman will attack a different unit.\n"
	text += " \n"

	text += "[color=GOLD]Fisherman's Net[/color]\n"
	text += "Creeps damaged by this tower get caught in its net.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.08)


func tower_init():
	fisherman_dps_boost_bt = BuffType.new("fisherman_dps_boost_bt", 0, 0, true, self)
	var fisherman_dps_boost_mod: Modifier = Modifier.new()
	fisherman_dps_boost_mod.add_modification(Modification.Type.MOD_DPS_ADD, 0.0, 0.001)
	fisherman_dps_boost_bt.set_buff_modifier(fisherman_dps_boost_mod)
	fisherman_dps_boost_bt.set_buff_icon("@@0@@")
	fisherman_dps_boost_bt.set_buff_tooltip("Fresh Fish!\nThis tower smells fresh fish; it has increased dps.")

	fisherman_slow_bt = BuffType.new("fisherman_slow_bt", 3, 0, false, self)
	var fisherman_slow_mod: Modifier = Modifier.new()
	fisherman_slow_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.25, -0.01)
	fisherman_slow_bt.set_buff_modifier(fisherman_slow_mod)
	fisherman_slow_bt.set_buff_icon("@@1@@")
	fisherman_slow_bt.add_event_on_create(fisherman_slow_bt_on_create)
	fisherman_slow_bt.add_event_on_expire(fisherman_slow_bt_on_expire)
	fisherman_slow_bt.set_buff_tooltip("Strangled\nThis unit is strangled; it has reduced movement speed.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Strangled Units")


func on_attack(event: Event):
	var tower: Tower = self
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

		if next != target && next.get_buff_of_type(fisherman_slow_bt) == null:
			CombatLog.log_ability(tower, next, "Impatient")
			tower.issue_target_order("attack", next)

			return

	tower.current_attack_count = 0


func on_damage(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	fisherman_slow_bt.apply(tower, target, level)


func on_tower_details() -> MultiboardValues:
	var strangle_count_string: String = str(strangle_count)
	multiboard.set_value(0, strangle_count_string)

	return multiboard


func fisherman_slow_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var net_start_time: float = GameTime.get_time()
	buff.user_real = net_start_time


func fisherman_slow_bt_on_expire(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var tower: Tower = buff.get_caster()
	var lvl: int = tower.get_level()
	var movespeed_for_strangle: float = 120 + 2.4 * lvl
	var net_start_time: float = buff.user_real
	var net_duration: float = GameTime.get_time() - net_start_time
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
	var tower: Tower = self
	var buff_level: int = int(1000 * tower.get_current_attack_damage_with_bonus() / tower.get_current_attackspeed() * (0.15 + 0.004 * tower.get_level()))
	var duration: float = 5.0 + 0.1 * tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		fisherman_dps_boost_bt.apply_custom_timed(tower, next, buff_level, duration)
