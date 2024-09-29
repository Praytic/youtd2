extends TowerBehavior


var ice_claw_bt: BuffType
var frenzy_bt: BuffType
var multiboard: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {frenzy_max_bonus = 1.0, buff_level = 0, spell_damage = 50, spell_damage_add = 2},
		2: {frenzy_max_bonus = 1.125, buff_level = 1, spell_damage = 100, spell_damage_add = 4},
		3: {frenzy_max_bonus = 1.25, buff_level = 2, spell_damage = 200, spell_damage_add = 8},
		4: {frenzy_max_bonus = 1.375, buff_level = 3, spell_damage = 400, spell_damage_add = 16},
		5: {frenzy_max_bonus = 1.5, buff_level = 4, spell_damage = 600, spell_damage_add = 24},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var frenzy_max_bonus: String = Utils.format_percent(_stats.frenzy_max_bonus, 2)
	
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Frenzy"
	ability.icon = "res://resources/icons/undead/skull_03.tres"
	ability.description_short = "Each time [color=GOLD]Ice Claw[/color] is cast, attack speed is increased permanently.\n"
	ability.description_full = "Each time [color=GOLD]Ice Claw[/color] is cast, attack speed is increased by 0.5%% permanently. This has a maximum of %s attack speed increase.\n" % frenzy_max_bonus \
	+ " \n" \
	+ "The stacks are lost if this tower is transformed into a tower of another family.\n" \
	+ ""
	list.append(ability)

	return list


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.0, 0.04)


func on_autocast(event: Event):
	if tower.user_real < _stats.frenzy_max_bonus:
		tower.user_real = tower.user_real + 0.005
		tower.user_int += 1
		tower.modify_property(Modification.Type.MOD_ATTACKSPEED, 0.005)

		var frenzy_buff: Buff = tower.get_buff_of_type(frenzy_bt)
		var stack_count: int = tower.user_int
		frenzy_buff.set_displayed_stacks(stack_count)

	Effect.create_simple_at_unit("res://src/effects/frost_bolt_missile.tscn", event.get_target())
	event.get_target().set_sprite_color(Color8(100, 100, 255, 255))
	ice_claw_bt.apply_custom_timed(tower, event.get_target(), _stats.buff_level, 5 + 0.2 * tower.get_level()).user_real = _stats.spell_damage + _stats.spell_damage_add * tower.get_level()


func drol_f_tundraStalker(event: Event):
	var b: Buff = event.get_buff()
	b.get_caster().do_spell_damage(b.get_buffed_unit(), b.user_real, b.get_caster().calc_spell_crit_no_bonus())


func drol_fade_tundraStalker(event: Event):
	var b: Buff = event.get_buff()
	b.get_buffed_unit().set_sprite_color(Color.WHITE)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_MOVESPEED, -0.2, -0.05)

	ice_claw_bt = BuffType.new("ice_claw_bt", 5, 0.2, false, self)
	ice_claw_bt.set_buff_modifier(m)
	
	ice_claw_bt.set_buff_icon("res://resources/icons/generic_icons/triple_scratches.tres")
	ice_claw_bt.add_periodic_event(drol_f_tundraStalker, 1)
	ice_claw_bt.add_event_on_cleanup(drol_fade_tundraStalker)

	ice_claw_bt.set_buff_tooltip("Ice Claw\nDeals spell damage over time and reduces movement speed.")

	frenzy_bt = BuffType.new("frenzy_bt", -1, 0, true, self)
	frenzy_bt.set_buff_icon("res://resources/icons/generic_icons/alligator_clip.tres")
	frenzy_bt.set_buff_tooltip("Frenzy\nPermanently increases attack speed.")

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Speed Bonus")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var spell_damage: String = Utils.format_float(_stats.spell_damage, 2)
	var spell_damage_add: String = Utils.format_float(_stats.spell_damage_add, 2)
	var slow_amount: String = Utils.format_percent(0.2 + 0.05 * _stats.buff_level, 2)

	autocast.title = "Ice Claw"
	autocast.icon = "res://resources/icons/magic/claw_02.tres"
	autocast.description_short = "Causes the target creep to be slowed and suffer spell damage over time.\n"
	autocast.description = "Ravages a target creep in 850 range, causing it to be slowed by %s and suffer %s spell damage per second. Effect lasts 5 seconds.\n" % [slow_amount, spell_damage] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage per second\n" % spell_damage_add \
	+ "+0.2 second duration\n"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 1
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.cast_range = 850
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 2
	autocast.is_extended = false
	autocast.mana_cost = 10
	autocast.buff_type = ice_claw_bt
	autocast.buff_target_type = null
	autocast.auto_range = 850
	autocast.handler = on_autocast

	return [autocast]


func on_create(preceding: Tower):
	if preceding != null && preceding.get_family() == tower.get_family():
		tower.user_real = preceding.user_real
		tower.user_int = preceding.user_int
		tower.modify_property(Modification.Type.MOD_ATTACKSPEED, preceding.user_real)
	else:
		tower.user_real = 0
		tower.user_int = 0

	var buff: Buff = frenzy_bt.apply_to_unit_permanent(tower, tower, 0)
	var stack_count: int = tower.user_int
	buff.set_displayed_stacks(stack_count)


func on_tower_details() -> MultiboardValues:
	var speed_bonus_text: String = Utils.format_percent(tower.user_real, 1)
	multiboard.set_value(0, speed_bonus_text)

	return multiboard
