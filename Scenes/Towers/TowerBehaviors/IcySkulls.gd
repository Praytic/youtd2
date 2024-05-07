extends TowerBehavior


var slow_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {slow_base = 0.075, slow_add = 0.003, duration_base = 3, duration_add = 0.1},
		2: {slow_base = 0.100, slow_add = 0.004, duration_base = 4, duration_add = 0.2},
		3: {slow_base = 0.125, slow_add = 0.005, duration_base = 5, duration_add = 0.3},
		4: {slow_base = 0.150, slow_add = 0.006, duration_base = 6, duration_add = 0.4},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var slow_base: String = Utils.format_percent(_stats.slow_base, 2)
	var slow_add: String = Utils.format_percent(_stats.slow_add, 2)
	var duration_base: String = Utils.format_float(_stats.duration_base, 2)
	var duration_add: String = Utils.format_float(_stats.duration_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Icy Touch"
	ability.description_short = "Slows attacked units.\n"
	ability.description_full = "Slows attacked units by %s for %s seconds.\n" % [slow_base, duration_base] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s seconds duration\n" % duration_add \
	+ "+%s slow" % slow_add
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func tower_init():
	slow_bt = BuffType.new("slow_bt", 0, 0, false, self)
	var slow_mod: Modifier = Modifier.new()
	slow_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0, -0.001)
	slow_bt.set_buff_icon("res://Resources/Textures/GenericIcons/foot_trip.tres")
	slow_bt.set_buff_modifier(slow_mod)

	slow_bt.set_buff_tooltip("Slow\nReduces movement speed.")


func on_damage(event: Event):
	var lvl: int = tower.get_level()
	var slow: int = int((_stats.slow_base + lvl * _stats.slow_add) * 1000)
	var dur: int = int(_stats.duration_base + lvl * _stats.duration_add)

	slow_bt.apply_custom_timed(tower, event.get_target(), slow, dur)
