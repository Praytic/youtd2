extends TowerBehavior


var zeal_bt: BuffType
var wound_bt: BuffType
var drain_bt: BuffType
var shield_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {affected_gold_cost = 200, shield_power = 400, wound_power = 0.02, wound_power_add = 0.0008, leech_power_base = 105, leech_power_add = 5},
		2: {affected_gold_cost = 460, shield_power = 650, wound_power = 0.04, wound_power_add = 0.0016, leech_power_base = 210, leech_power_add = 10},
		3: {affected_gold_cost = 750, shield_power = 800, wound_power = 0.06, wound_power_add = 0.0024, leech_power_base = 315, leech_power_add = 15},
		4: {affected_gold_cost = 1200, shield_power = 1000, wound_power = 0.08, wound_power_add = 0.0032, leech_power_base = 420, leech_power_add = 20},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var affected_gold_cost: String = Utils.format_float(_stats.affected_gold_cost, 2)
	var shield_power: String = Utils.format_percent(_stats.shield_power * 0.0001, 2)
	var wound_power: String = Utils.format_percent(_stats.wound_power, 2)
	var wound_power_add: String = Utils.format_percent(_stats.wound_power_add, 2)
#	NOTE: use floor to approximate the value of leech/stack down to nearest percent
	var leech_power_base: String = Utils.format_percent(floor(_stats.leech_power_base * 0.01) * 0.01, 2)

	var list: Array[AbilityInfo] = []
	
	var zeal: AbilityInfo = AbilityInfo.new()
	zeal.name = "Zeal"
	zeal.icon = "res://resources/icons/holy/cross_01.tres"
	zeal.description_short = "Each attack works the Zealot into a greater frenzy, increasing his attack speed but slowing nearby towers.\n"
	zeal.description_full = "Each attack works the Zealot into a greater frenzy, increasing his attack speed by %s from each tower in 175 range. These towers have their attack speed slowed by %s. Both effects stack up to 5 times and last 2.5 seconds. The attack speed amount reduces slightly with more towers.\n" % [leech_power_base, leech_power_base] \
	+ " \n" \
	+ "Only towers that cost %s gold or more are affected by this.\n" % affected_gold_cost \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1 max stack per 5 levels\n"
	list.append(zeal)

	var lightning_shield: AbilityInfo = AbilityInfo.new()
	lightning_shield.name = "Lightning Shield"
	lightning_shield.icon = "res://resources/icons/tower_icons/lightning_generator.tres"
	lightning_shield.description_short = "As the zealot gets pumped up debuff durations are reduced.\n"
	lightning_shield.description_full = "As the zealot gets pumped up debuff durations are reduced by %s with each stack of [color=GOLD]Zeal[/color].\n" % shield_power
	list.append(lightning_shield)

	var phase_blade: AbilityInfo = AbilityInfo.new()
	phase_blade.name = "Phase Blade"
	phase_blade.icon = "res://resources/icons/swords/sword_swing_02.tres"
	phase_blade.description_short = "Each hit on the same creep penetrates deeper through its armor.\n"
	phase_blade.description_full = "Each hit on the same creep penetrates deeper through its armor. Per hit %s of this tower's attack damage won't be reduced by armor resistances. This effect stacks up to 5 times.\n" % wound_power \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage per stack\n" % wound_power_add
	list.append(phase_blade)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_attack(on_attack)



func shield_bt_cleanup(event: Event):
	var b: Buff = event.get_buff()

	if b.user_int2 != 0:
		Effect.destroy_effect(b.user_int2)


func tower_init():
	var m: Modifier = Modifier.new()
	var n: Modifier = Modifier.new()
	var o: Modifier = Modifier.new()

	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.0001)
	n.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, -0.0001)
	o.add_modification(Modification.Type.MOD_DEBUFF_DURATION, 0.0, -0.0001)

	zeal_bt = BuffType.new("zeal_bt", 2.5, 0, true, self)
	wound_bt = BuffType.new("wound_bt", 200, 0, false, self)
	drain_bt = BuffType.new("drain_bt", 2.5, 0, true, self)
	shield_bt = BuffType.new("shield_bt", 2.5, 0, true, self)

	zeal_bt.set_buff_modifier(m)
	drain_bt.set_buff_modifier(n)
	shield_bt.set_buff_modifier(o)

	zeal_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	wound_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	drain_bt.set_buff_icon("res://resources/icons/generic_icons/energy_breath.tres")
	shield_bt.set_buff_icon("res://resources/icons/generic_icons/turtle_shell.tres")

	zeal_bt.set_buff_tooltip("Zeal\nIncreases attack speed.")
	wound_bt.set_buff_tooltip("Phase Wound\nZealot's attacks will penetrate through some of the armor.")
	drain_bt.set_buff_tooltip("Zeal Drain\nDecreases attack speed.")
	shield_bt.set_buff_tooltip("Lightning Shield\nReduces debuff duration.")

	shield_bt.add_event_on_cleanup(shield_bt_cleanup)


func on_attack(_event: Event):
	var b: Buff
	var u: Tower
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 175.0)
	var leech_counter: int = 0
	var leech_power: int
	var max_stacks: int = 5 + tower.get_level() / 5

	while true:
		u = it.next()

		if u == null:
			break

		if u != tower && u.get_gold_cost() >= _stats.affected_gold_cost:
			leech_counter = leech_counter + 1

	if leech_counter == 0:
		return

# 	1% leech per tower with 1 tower, 0.65% per tower with 8 
	leech_power = _stats.leech_power_base - _stats.leech_power_add * leech_counter

	it = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 175.0)

# 	Slows all towers in 175 range
	while true:
		u = it.next()

		if u == null:
			break

		if u != tower && u.get_gold_cost() >= _stats.affected_gold_cost:
			b = u.get_buff_of_type(drain_bt)

			var active_stacks: int
			if b != null:
				active_stacks = b.user_int
			else:
				active_stacks = 0

			var new_stacks: int = min(active_stacks + 1, max_stacks)
			var new_buff_level: int = leech_power * new_stacks

			b = drain_bt.apply(tower, u, new_buff_level)
			b.user_int = new_stacks
			b.set_displayed_stacks(new_stacks)

#	in a way, that's the per stack base
	leech_power = leech_power * leech_counter
	b = tower.get_buff_of_type(zeal_bt)

	var active_stacks: int
	if b != null:
		active_stacks = b.user_int
	else:
		active_stacks = 0

	var new_stacks: int = min(active_stacks + 1, max_stacks)
	var new_buff_level: int = leech_power * new_stacks

#	now apply zeal
	b = zeal_bt.apply(tower, tower, new_buff_level)
	b.user_int = new_stacks
	b.set_displayed_stacks(new_stacks)
	
	b = tower.get_buff_of_type(shield_bt)

	if b != null:
		if b.user_int < max_stacks:
			b.user_int = b.user_int + 1

			if b.user_int == max_stacks:
				if b.user_int2 == 0:
					b.user_int2 = Effect.create_simple_at_unit("res://src/effects/bdragon_26_whirlpool_cycle.tscn", tower)
					Effect.set_auto_destroy_enabled(b.user_int2, false)

		shield_bt.apply(tower, tower, _stats.shield_power * b.user_int)
	else:
		b = shield_bt.apply(tower, tower, _stats.shield_power)
		b.user_int = 1
		b.user_int2 = 0


func on_damage(event: Event):
	var target: Creep = event.get_target()
	var phase_wound: Buff = target.get_buff_of_type(wound_bt)
	var damage_base: float = event.damage
	var total_armor_pierce: float
	var temp: float = AttackType.get_damage_against(AttackType.enm.PHYSICAL, target.get_armor_type())

	if event.is_spell_damage() || !event.is_main_target():
		return

#	first check + upgrade the wound level
	if phase_wound == null:
		phase_wound = wound_bt.apply(tower, target, 1)
#		stack counter
		phase_wound.user_int = 1
		phase_wound.user_int2 = tower.get_instance_id()
	else:
#		multiple zealots + family member check. If another zealot attacks, no armor pierce for him
#		only the guy who put the first wound gets armor pierce
#		perfection would need hashtables storing wound level for every tower,creep pair. Not worth it i think.
		if phase_wound.user_int2 != tower.get_instance_id():
			return

		phase_wound.user_int = min(5, phase_wound.user_int + 1)
		phase_wound.refresh_duration()

	if phase_wound != null:
		phase_wound.set_displayed_stacks(phase_wound.user_int)

#	ignoring armor type "resistance" not weakness :P
	if temp > 0.001 && temp < 1.0:
		damage_base = damage_base / temp

	temp = 1 - target.get_current_armor_damage_reduction()

	if temp > 0.001 && temp < 1.0:
		damage_base = damage_base / temp

	total_armor_pierce = (_stats.wound_power + _stats.wound_power_add * tower.get_level()) * phase_wound.user_int

	if event.damage < damage_base:
		event.damage = damage_base * total_armor_pierce + event.damage * (1.0 - total_armor_pierce)
