extends TowerBehavior


var ignite_bt: BuffType


const IGNITE_DURATION: float = 5.0
const IGNITE_DURATION_ADD: float = 0.05
const IGNITE_DAMAGE_PERIOD: float = 0.5


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_dmg_from_fire = 0.07, buff_level_per_stack = 1, buff_power = 70},
		2: {mod_dmg_from_fire = 0.14, buff_level_per_stack = 2, buff_power = 140},
		3: {mod_dmg_from_fire = 0.21, buff_level_per_stack = 4, buff_power = 210},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []

	var ignite_duration: String = Utils.format_float(IGNITE_DURATION, 2)
	var ignite_duration_add: String = Utils.format_float(IGNITE_DURATION_ADD, 2)
	var ignite_damage_period: String = Utils.format_float(IGNITE_DAMAGE_PERIOD, 2)
	var dmg_from_fire: String = Utils.format_percent(_stats.mod_dmg_from_fire, 2)
	var spell_damage: String = Utils.format_float(35 * _stats.buff_level_per_stack, 2)
	var spell_damage_add: String = Utils.format_float(1.4 * _stats.buff_level_per_stack, 2)
	var fire_string: String = Element.convert_to_colored_string(Element.enm.FIRE)
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Ignite"
	ability.icon = "res://resources/icons/orbs/orb_fire.tres"
	ability.description_short = "Ignites hit creeps, causing spell damage over time and increasing vulnerability to %s towers.\n" % fire_string
	ability.description_full = "Ignites hit creeps, causing %s spell damage every %s seconds for %s seconds and increasing vulnerability to %s towers by %s. The damage over time effect stacks.\n" % [spell_damage, ignite_damage_period, ignite_duration, fire_string, dmg_from_fire] \
	+ " \n" \
	+ "If there are multiple towers of this family, then the first hitting tower will own the [color=GOLD]Ignite[/color].\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage \n" % spell_damage_add \
	+ "+%s seconds duration\n" % ignite_duration_add

	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	tower.set_target_count(4)


# NOTE: sir_area_damage() in original script
func ignite_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var buff_level: int = buff.get_level()
	var damage: float = (35 + 1.4 * level) * buff_level

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())


func tower_init():
	ignite_bt = BuffType.new("ignite_bt", IGNITE_DURATION, IGNITE_DURATION_ADD, false, self)
	ignite_bt.set_buff_icon("res://resources/icons/generic_icons/flame.tres")
	ignite_bt.set_buff_tooltip("Ignite\nDeals spell damage over time and increases damage taken from Fire towers.")
	ignite_bt.add_periodic_event(ignite_bt_periodic, IGNITE_DAMAGE_PERIOD)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_FROM_FIRE, _stats.mod_dmg_from_fire, 0.0)
	ignite_bt.set_buff_modifier(mod)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var buff: Buff = target.get_buff_of_type(ignite_bt)

	if buff != null:
		tower.user_int = buff.get_level() + _stats.buff_level_per_stack
		tower.user_int2 = max(buff.get_power(), _stats.buff_power)
	else:
		tower.user_int = _stats.buff_level_per_stack
		tower.user_int2 = _stats.buff_power

	var buff_level: int = tower.user_int
	var buff_power: int = tower.user_int2
	ignite_bt.apply_custom_power(tower, target, buff_level, buff_power)

	buff = target.get_buff_of_type(ignite_bt)
	if buff != null:
		var stack_count: int = buff.get_level() / _stats.buff_level_per_stack
		buff.set_displayed_stacks(stack_count)
