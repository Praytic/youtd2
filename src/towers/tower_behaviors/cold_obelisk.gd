extends TowerBehavior


var slow_bt: BuffType


const SLOW_DURATION: float = 4.0


func get_tier_stats() -> Dictionary:
	return {
		1: {splash_radius = 140, mod_movespeed = 0.18, mod_movespeed_add = 0.0040},
		2: {splash_radius = 180, mod_movespeed = 0.24, mod_movespeed_add = 0.0045},
		3: {splash_radius = 220, mod_movespeed = 0.30, mod_movespeed_add = 0.0050},
	}


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var mod_movespeed: String = Utils.format_percent(_stats.mod_movespeed, 2)
	var mod_movespeed_add: String = Utils.format_percent(_stats.mod_movespeed_add, 2)
	var slow_duration: String = Utils.format_float(SLOW_DURATION, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Absolute Zero"
	ability.icon = "res://resources/icons/tower_icons/ebonfrost_crystal.tres"
	ability.description_short = "Slows hit creeps.\n"
	ability.description_full = "Slows hit creeps by %s for %s seconds.\n" % [mod_movespeed, slow_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s slow\n" % mod_movespeed_add
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials_DELETEME(modifier: Modifier):
	tower.set_attack_style_splash_DELETEME({_stats.splash_radius: 0.35})

	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.45, 0.02)


func tower_init():
	slow_bt = BuffType.new("slow_bt", SLOW_DURATION, 0, false, self)
	var slow_bt_mod: Modifier = Modifier.new()
	slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, -_stats.mod_movespeed, -_stats.mod_movespeed_add)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	slow_bt.set_buff_modifier(slow_bt_mod)
	slow_bt.set_buff_tooltip("Absolute Zero\nReduces movement speed.")


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	slow_bt.apply(tower, target, level)
