extends TowerBehavior


var ignite_bt: BuffType


const IGNITE_DURATION: float = 5.0
const IGNITE_DURATION_ADD: float = 0.05
const IGNITE_DAMAGE_PERIOD: float = 0.5


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_dmg_from_fire = 0.07, ignite_damage = 35, ignite_damage_add = 1.4},
		2: {mod_dmg_from_fire = 0.14, ignite_damage = 70, ignite_damage_add = 2.8},
		3: {mod_dmg_from_fire = 0.21, ignite_damage = 140, ignite_damage_add = 5.6},
	}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []

	var ignite_duration: String = Utils.format_float(IGNITE_DURATION, 2)
	var ignite_duration_add: String = Utils.format_float(IGNITE_DURATION_ADD, 2)
	var ignite_damage_period: String = Utils.format_float(IGNITE_DAMAGE_PERIOD, 2)
	var dmg_from_fire: String = Utils.format_percent(_stats.mod_dmg_from_fire, 2)
	var ignite_damage: String = Utils.format_float(_stats.ignite_damage, 2)
	var ignite_damage_add: String = Utils.format_float(1.4 * _stats.ignite_damage_add, 2)
	var fire_string: String = Element.convert_to_colored_string(Element.enm.FIRE)
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Ignite"
	ability.icon = "res://resources/icons/orbs/orb_fire.tres"
	ability.description_short = "Ignites hit creeps, causing spell damage over time and increasing vulnerability to %s towers.\n" % fire_string
	ability.description_full = "Ignites hit creeps, causing %s spell damage every %s seconds for %s seconds and increasing vulnerability to %s towers by %s. The damage over time effect stacks.\n" % [ignite_damage, ignite_damage_period, ignite_duration, fire_string, dmg_from_fire] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage \n" % ignite_damage_add \
	+ "+%s seconds duration\n" % ignite_duration_add

	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials_DELETEME(_modifier: Modifier):
	tower.set_target_count_DELETEME(4)


# NOTE: sir_area_damage() in original script
func ignite_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = event.get_target()
	var ignite_damage: float = buff.user_real

	tower.do_spell_damage(target, ignite_damage, tower.calc_spell_crit_no_bonus())


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
	var level: int = tower.get_level()

	var active_buff: Buff = target.get_buff_of_type(ignite_bt)
	var active_stacks: int = 0
	var active_damage: float = 0
	if active_buff != null:
		active_stacks = active_buff.user_int
		active_damage = active_buff.user_real

	var new_stacks: int = active_stacks + 1
	var added_damage: float = _stats.ignite_damage + _stats.ignite_damage_add * level
	var new_damage: float = active_damage + added_damage

#	NOTE: weaker tier tower increases damage without
#	refreshing duration
	active_buff = ignite_bt.apply(tower, target, 1)
	active_buff.user_int = new_stacks
	active_buff.set_displayed_stacks(new_stacks)
	active_buff.user_real = new_damage
