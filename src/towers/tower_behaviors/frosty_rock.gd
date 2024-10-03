extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Removed floating text for
# ability chance because it popped up on every attack and
# was annoying. Added display of this chance in tower
# details instead.


var slow_bt: BuffType
var stun_bt: BuffType
var multiboard : MultiboardValues


const SLOW_DURATION: float = 3.0


var accumulated_chance: float = 0.0


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_movespeed = 0.070, mod_movespeed_add = 0.0035, wrath_damage = 100, wrath_damage_add = 2, damage_and_stun_chance = 0.02, stun_duration = 0.8},
		2: {mod_movespeed = 0.100, mod_movespeed_add = 0.0050, wrath_damage = 520, wrath_damage_add = 10.4, damage_and_stun_chance = 0.03, stun_duration = 0.9},
		3: {mod_movespeed = 0.130, mod_movespeed_add = 0.0065, wrath_damage = 1300, wrath_damage_add = 26, damage_and_stun_chance = 0.04, stun_duration = 1.0},
		4: {mod_movespeed = 0.160, mod_movespeed_add = 0.0080, wrath_damage = 2150, wrath_damage_add = 43, damage_and_stun_chance = 0.05, stun_duration = 1.1},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var slow_duration: String = Utils.format_float(SLOW_DURATION, 2)
	var mod_movespeed: String = Utils.format_percent(_stats.mod_movespeed, 2)
	var mod_movespeed_add: String = Utils.format_percent(_stats.mod_movespeed_add, 2)
	var wrath_damage: String = Utils.format_float(_stats.wrath_damage, 2)
	var wrath_damage_add: String = Utils.format_float(_stats.wrath_damage_add, 2)
	var stun_duration: String = Utils.format_float(_stats.stun_duration, 2)
	var damage_and_stun_chance: String = Utils.format_percent(_stats.damage_and_stun_chance, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Glacial Wrath"
	ability.icon = "res://resources/icons/tower_icons/genis_sage.tres"
	ability.description_short = "Slows hit creeps and has a chance to stun.\n"
	ability.description_full = "Slows hit creeps by %s for %s seconds. There's also a %s chance to deal %s spell damage and stun the creep for %s seconds. Whenever the stun fails to happen, the chance is increased by %s. Bonus chance resets when stun suceeds.\n" % [mod_movespeed, slow_duration, damage_and_stun_chance, wrath_damage, stun_duration, damage_and_stun_chance] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage\n" % wrath_damage_add \
	+ "+%s slow\n" % mod_movespeed_add
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	slow_bt = BuffType.new("slow_bt", SLOW_DURATION, 0, false, self)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	slow_bt.set_buff_tooltip("Glacial Wrath\nReduces movement speed.")
	var slow_bt_mod: Modifier = Modifier.new()
	slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, -_stats.mod_movespeed, -_stats.mod_movespeed_add)
	slow_bt.set_buff_modifier(slow_bt_mod)

	stun_bt = CbStun.new("stun_bt", _stats.stun_duration, 0, false, self)

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Wrath stun chance")


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	slow_bt.apply(tower, target, level)

	if tower.calc_chance(accumulated_chance) == true && !event.get_target().is_immune():
		CombatLog.log_ability(tower, target, "Glacial Wrath Bonus")

		stun_bt.apply(tower, target, level)
		var wrath_damage: float = _stats.wrath_damage + _stats.wrath_damage_add * level
		tower.do_spell_damage(target, wrath_damage, tower.calc_spell_crit_no_bonus())
		accumulated_chance = _stats.damage_and_stun_chance
	else:
		accumulated_chance += _stats.damage_and_stun_chance


func on_create(_preceding_tower: Tower):
	accumulated_chance = _stats.damage_and_stun_chance


func on_tower_details() -> MultiboardValues:
	var accumulated_chance_text: String = Utils.format_percent(accumulated_chance, 2)
	multiboard.set_value(0, accumulated_chance_text)
	
	return multiboard
