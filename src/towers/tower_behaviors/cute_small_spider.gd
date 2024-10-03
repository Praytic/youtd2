extends TowerBehavior


# NOTE: in original script an EventTypeList is used to add
# "on_damage" event handler. Changed script to add handler
# directly to tower.

# NOTE: [ORIGINAL_GAME_DEVIATION] removed mechanic of Poison
# getting replaced when a tower with higher "spell damage
# dealt" applies it. It's not good because a lower tier
# Spider could randomly get a big boost to "spell damage
# dealt" from some ability or item, which would incorrectly
# replace the more powerful Poison.


var poison_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 30, damage_add = 1.5, max_damage = 150, max_damage_add = 7.5},
		2: {damage = 90, damage_add = 4.5, max_damage = 450, max_damage_add = 22.5},
		3: {damage = 270, damage_add = 13.5, max_damage = 1350, max_damage_add = 67.5},
		4: {damage = 750, damage_add = 37.5, max_damage = 3750, max_damage_add = 187.5},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var damage: String = Utils.format_float(_stats.damage, 2)
	var damage_add: String = Utils.format_float(_stats.damage_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Poisonous Spittle"
	ability.icon = "res://resources/icons/misc/poison_01.tres"
	ability.description_short = "Infects hit creeps, dealing spell damage over time.\n"
	ability.description_full = "Infects hit creeps, dealing %s spell damage per second for 5 seconds. Further attacks on the same creep will increase the potency of the infection, stacking the damage and refreshing duration. Limit of 5 stacks.\n" % damage \
	+ " \n" \
	+ "If there are multiple towers of this family, then [color=GOLD]Poisonous Spittle[/color] damage at 5 stacks will be equal to damage of the most powerful tower.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage per second\n" % damage_add \
	+ "+0.05 second duration\n" \
	+ "+1 stack every 5 levels\n"
	list.append(ability)

	return list


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_NATURE, -0.30, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.10, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.20, 0.0)


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


# NOTE: D1000_Spider_Damage() in original script
func poison_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var poison_damage: float = buff.user_real
	
	tower.do_spell_damage(target, poison_damage, tower.calc_spell_crit_no_bonus())


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	var active_buff: Buff = target.get_buff_of_type(poison_bt)
	
	var active_stacks: int = 0
	var active_damage: float = 0
	var active_damage_cap: float = 0
	if active_buff != null:
		active_stacks = active_buff.user_int
		active_damage = active_buff.user_real
		active_damage_cap = active_buff.user_real2

	var new_stacks: int = min(active_stacks + 1, 5)
	var added_damage: float = _stats.damage + _stats.damage_add * level
	var this_damage_cap: float = _stats.max_damage + _stats.max_damage_add * level
	var new_damage_cap: float = max(active_damage_cap, this_damage_cap)
	var new_damage: float = min(active_damage + added_damage, new_damage_cap)

#	NOTE: weaker tier tower increases damage without
#	refreshing duration
	active_buff = poison_bt.apply(tower, target, 1)
	active_buff.user_int = new_stacks
	active_buff.set_displayed_stacks(new_stacks)
	active_buff.user_real = new_damage
	active_buff.user_real2 = new_damage_cap


func tower_init():
	poison_bt = BuffType.new("poison_bt", 5, 0.05, false, self)
	poison_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	poison_bt.add_periodic_event(poison_bt_periodic, 1)
	poison_bt.set_buff_tooltip("Poisonous Spittle\nDeals damage over time.")
