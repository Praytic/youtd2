extends Tower


var storm_zealot_fury: BuffType
var storm_zealot_wound: BuffType
var storm_zealot_slow: BuffType
var storm_zealot_shield: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {affected_gold_cost = 200, shield_power = 400, wound_power = 0.02, wound_power_add = 0.0008, leech_power_base = 105, leech_power_add = 5},
		2: {affected_gold_cost = 460, shield_power = 650, wound_power = 0.04, wound_power_add = 0.0016, leech_power_base = 210, leech_power_add = 10},
		3: {affected_gold_cost = 750, shield_power = 800, wound_power = 0.06, wound_power_add = 0.0024, leech_power_base = 315, leech_power_add = 15},
		4: {affected_gold_cost = 1200, shield_power = 1000, wound_power = 0.08, wound_power_add = 0.0032, leech_power_base = 420, leech_power_add = 20},
	}


func get_ability_description() -> String:
	var affected_gold_cost: String = Utils.format_float(_stats.affected_gold_cost, 2)
	var shield_power: String = Utils.format_percent(_stats.shield_power * 0.0001, 2)
	var wound_power: String = Utils.format_percent(_stats.wound_power, 2)
	var wound_power_add: String = Utils.format_percent(_stats.wound_power_add, 2)
#	NOTE: use floor to approximate the value of leech/stack down to nearest percent
	var leech_power_base: String = Utils.format_percent(floor(_stats.leech_power_base * 0.01) * 0.01, 2)

	var text: String = ""

	text += "[color=GOLD]Lightning Shield[/color]\n"
	text += "As the zealot gets pumped up debuff durations are reduced by %s with each stack of Zeal.\n" % shield_power
	text += " \n"

	text += "[color=GOLD]Zeal[/color]\n"
	text += "Each attack works the Zealot into a greater frenzy, increasing his attack speed by %s from each tower in 175 range. These towers have their attack speed slowed by %s. Both effects stack up to 5 times and last 2.5 seconds. The attack speed amount reduces slightly with more towers.\nOnly towers that cost %s gold or more are affected by this.\n" % [leech_power_base, leech_power_base, affected_gold_cost]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1 max stack per 5 levels\n"
	text += " \n"

	text += "[color=GOLD]Phase Blade[/color]\n"
	text += "Each attack on the same creep penetrates deeper through its armor. Per attack %s of this tower's attack damage won't be reduced by armor resistances. This effect stacks up to 5 times.\n" % wound_power
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage per stack\n" % wound_power_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_attack(on_attack)



func storm_zealot_shield_cleanup(event: Event):
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

	storm_zealot_fury = BuffType.new("storm_zealot_fury", 2.5, 0, true, self)
	storm_zealot_wound = BuffType.new("storm_zealot_wound", 200, 0, false, self)
	storm_zealot_slow = BuffType.new("storm_zealot_slow", 2.5, 0, true, self)
	storm_zealot_shield = BuffType.new("storm_zealot_shield", 2.5, 0, true, self)

	storm_zealot_fury.set_buff_modifier(m)
	storm_zealot_slow.set_buff_modifier(n)
	storm_zealot_shield.set_buff_modifier(o)

	storm_zealot_fury.set_buff_icon("@@0@@")
	storm_zealot_wound.set_buff_icon("@@1@@")
	storm_zealot_slow.set_buff_icon("@@3@@")
	storm_zealot_shield.set_buff_icon("@@2@@")

	storm_zealot_fury.set_buff_tooltip("Zeal\nThis tower is affected by Zeal; it has increased attack speed.")
	storm_zealot_wound.set_buff_tooltip("Phase Wound\nThis unit is wounded by a phase blade; zealot's attacks against this unit will penetrate through some of the unit's armor.")
	storm_zealot_slow.set_buff_tooltip("Zeal Drain\nThis tower is affected by Zeal Drain; it has decreased attack speed.")
	storm_zealot_shield.set_buff_tooltip("Lightning Shield\nThis tower is affected by Lightning Shield; it has reduced debuff duration.")

	storm_zealot_shield.add_event_on_cleanup(storm_zealot_shield_cleanup)


func on_attack(_event: Event):
	var tower: Tower = self
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
	leech_power = 105 - 5 * leech_counter

	it = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 175.0)

# 	Slows all towers in 175 range
	while true:
		u = it.next()

		if u == null:
			break

		if u != tower && u.get_gold_cost() >= _stats.affected_gold_cost:
			b = u.get_buff_of_type(storm_zealot_slow)

			if b != null:
				b.user_int = min(b.user_int + 1, max_stacks)
				storm_zealot_slow.apply_custom_power(tower, u, b.user_int, leech_power * b.user_int)
			else:
				storm_zealot_slow.apply_custom_power(tower, u, 1, leech_power).user_int = 1

#	in a way, that's the per stack base
	leech_power = leech_power * leech_counter
	b = tower.get_buff_of_type(storm_zealot_fury)

#	now apply zeal
	if b != null:
		storm_zealot_fury.apply(tower, tower, min(leech_power + b.get_level(), leech_power * max_stacks))
	else:
		storm_zealot_fury.apply(tower, tower, leech_power)

	b = tower.get_buff_of_type(storm_zealot_shield)

	if b != null:
		if b.user_int < max_stacks:
			b.user_int = b.user_int + 1

			if b.user_int == max_stacks:
				if b.user_int2 == 0:
					b.user_int2 = Effect.create_scaled("ManaShieldCaster.mdl", tower.get_visual_x(), tower.get_visual_y(), 115, 0, 0.65)

		storm_zealot_shield.apply(tower, tower, _stats.shield_power * b.user_int)
	else:
		b = storm_zealot_shield.apply(tower, tower, _stats.shield_power)
		b.user_int = 1
		b.user_int2 = 0


func on_damage(event: Event):
	var tower: Tower = self
	var target: Creep = event.get_target()
	var phase_wound: Buff = target.get_buff_of_type(storm_zealot_wound)
	var damage_base: float = event.damage
	var total_armor_pierce: float
	var temp: float = AttackType.get_damage_against(AttackType.enm.PHYSICAL, target.get_armor_type())

	if event.is_spell_damage() || !event.is_main_target():
		return

#	first check + upgrade the wound level
	if phase_wound == null:
		phase_wound = storm_zealot_wound.apply(tower, target, 1)
#		stack counter
		phase_wound.user_int = 1
		phase_wound.user_int2 = Utils.getUID(tower)
	else:
#		multiple zealots + family member check. If another zealot attacks, no armor pierce for him
#		only the guy who put the first wound gets armor pierce
#		perfection would need hashtables storing wound level for every tower,creep pair. Not worth it i think.
		if phase_wound.user_int2 != Utils.getUID(tower):
			return

		phase_wound.user_int = min(5, phase_wound.user_int + 1)
		phase_wound.refresh_duration()

#	ignoring armor type "resistance" not weakness :P
	if temp > 0.001 && temp < 1.0:
		damage_base = damage_base / temp

	temp = 1 - target.get_current_armor_damage_reduction()

	if temp > 0.001 && temp < 1.0:
		damage_base = damage_base / temp

	total_armor_pierce = (_stats.wound_power + _stats.wound_power_add * tower.get_level()) * phase_wound.user_int

	if event.damage < damage_base:
		event.damage = damage_base * total_armor_pierce + event.damage * (1.0 - total_armor_pierce)

