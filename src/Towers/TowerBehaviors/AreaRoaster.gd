extends TowerBehavior


var ignite_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {buff_level_per_stack = 1, buff_power = 70},
		2: {buff_level_per_stack = 2, buff_power = 140},
		3: {buff_level_per_stack = 4, buff_power = 210},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []

	var dmg_from_fire: String = Utils.format_percent(_stats.buff_power * 0.001, 2)
	var spell_damage: String = Utils.format_float(35 * _stats.buff_level_per_stack, 2)
	var spell_damage_add: String = Utils.format_float(1.4 * _stats.buff_level_per_stack, 2)
	var fire_string: String = Element.convert_to_colored_string(Element.enm.FIRE)
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Ignite"
	ability.icon = "res://resources/icons/orbs/orb_fire.tres"
	ability.description_short = "Whenever this tower hits a creep, it applies [color=GOLD]Ignite[/color]. [color=GOLD]Ignite[/color] causes the target to receive more damage from %s towers and deals spell damage over time.\n" % fire_string
	ability.description_full = "Whenever this tower hits a creep, it applies [color=GOLD]Ignite[/color]. [color=GOLD]Ignite[/color] causes the target to receive %s more damage from %s towers and deals %s spell damage every 0.5 seconds for 5 seconds. The damage over time effect stacks.\n" % [dmg_from_fire, fire_string, spell_damage] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage \n" % spell_damage_add \
	+ "+0.05 seconds duration\n"

	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	tower.set_target_count(4)


# NOTE: sir_area_damage() in original script
func ignite_bt_periodic(event: Event):
	var b: Buff = event.get_buff()
	var caster: Tower = b.get_caster()

	caster.do_spell_damage(b.get_buffed_unit(), (35 + caster.get_level() * 1.4) * b.get_level(), caster.calc_spell_crit_no_bonus())


func tower_init():
	ignite_bt = BuffType.new("ignite_bt", 0, 0, false, self)
	ignite_bt.set_buff_icon("res://resources/icons/GenericIcons/flame.tres")
	ignite_bt.set_buff_tooltip("Ignite\nDeals spell damage over time and increases damage taken from Fire towers.")
	ignite_bt.set_stacking_group("ignite_bt")
	ignite_bt.add_periodic_event(ignite_bt_periodic, 0.5)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_FROM_FIRE, 0.0, 0.001)
	ignite_bt.set_buff_modifier(mod)


func on_damage(event: Event):
	var buffyourno: Buff = event.get_target().get_buff_of_type(ignite_bt)

	if buffyourno != null:
		tower.user_int = buffyourno.get_level() + _stats.buff_level_per_stack
		tower.user_int2 = max(buffyourno.get_power(), _stats.buff_power)
	else:
		tower.user_int = _stats.buff_level_per_stack
		tower.user_int2 = _stats.buff_power

	ignite_bt.apply_advanced(tower, event.get_target(), tower.user_int, tower.user_int2, 5 + tower.get_level() * 0.05)
