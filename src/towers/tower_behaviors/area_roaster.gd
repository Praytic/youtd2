extends TowerBehavior


# NOTE: this tower behaves slightly differently compared to
# original youtd, because youtd2 prioritizes higher tier
# buffs.
# 
# Original youtd: any tower from family would refresh
# Ignite. First hitting tower would own Ignite, even if it's
# lower tier. Each tower added damage to ignite based on
# it's tier.
# 
# Youtd2: Higher tier towers will overwrite Ignite from
# lower tier towers. In addition, lower tier towers have no
# effect on Ignite from higher tier tower - no refresh or
# stack increase.


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


func get_ability_info_list() -> Array[AbilityInfo]:
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
	+ "If there are multiple towers of this family, then the first hitting tower will own the [color=GOLD]Ignite[/color] and other towers will refresh duration and add damage over time. Other towers with lower tier than owner of [color=GOLD]Ignite[/color] will not refresh duration and will not increase stack count.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage \n" % ignite_damage_add \
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
	var stack_count: int = buff.get_level()
	var ignite_damage: float = (_stats.ignite_damage + _stats.ignite_damage_add * level) * stack_count

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
	var buff: Buff = target.get_buff_of_type(ignite_bt)
	var level: int = tower.get_level()

	var new_stack_count: int = 1

#	NOTE: need to inherit active stacks only if tier of
#	active caster is same or greater. Otherwise, it would be
#	possible to build low tier towers to stack up Ignites
#	and then switch to more powerful Ignite from higher tier
#	tower, without losing stacks.
	if buff != null:
		var active_caster: Tower = buff.get_caster()
		var active_caster_tier: int = active_caster.get_tier()
		var this_tier: int = tower.get_tier()
		var active_caster_tier_is_same_or_greater: bool = active_caster_tier >= this_tier

		if active_caster_tier_is_same_or_greater:
			var active_stack_count: int = buff.get_level()
			new_stack_count += active_stack_count

	var buff_level: int = new_stack_count
	var buff_power: int = level
	buff = ignite_bt.apply_custom_power(tower, target, buff_level, buff_power)

#	NOTE: actual stack count may be different if apply was
#	rejected
	var actual_stack_count: int = buff.get_level()
	buff.set_displayed_stacks(actual_stack_count)
