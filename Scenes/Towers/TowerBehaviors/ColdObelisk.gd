extends TowerBehavior


var slow_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {splash_radius = 140, slow_power = 18, slow_power_add = 0.40},
		2: {splash_radius = 180, slow_power = 24, slow_power_add = 0.45},
		3: {splash_radius = 220, slow_power = 30, slow_power_add = 0.50},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var slow_amount: String = Utils.format_percent(_stats.slow_power * 10 * 0.001, 2)
	var slow_amount_add: String = Utils.format_percent(_stats.slow_power_add * 10 * 0.001, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Absolute Zero"
	ability.icon = "res://Resources/Icons/TowerIcons/EbonfrostCrystal.tres"
	ability.description_short = "Whenever this tower hits a creep, it slows the creep.\n"
	ability.description_full = "Whenever this tower hits a creep, it slows the creep by %s for 4 seconds.\n" % slow_amount \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s slow\n" % slow_amount_add
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	tower.set_attack_style_splash({_stats.splash_radius: 0.35})

	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.45, 0.02)


func tower_init():
	var slow: Modifier = Modifier.new()
	slow.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	slow_bt = BuffType.new("slow_bt", 0, 0, false, self)
	slow_bt.set_buff_icon("res://Resources/Icons/GenericIcons/foot_trip.tres")
	slow_bt.set_buff_modifier(slow)
	slow_bt.set_buff_tooltip("Absolute Zero\nReduces movement speed.")


func on_damage(event: Event):
	var s: int = int((_stats.slow_power + tower.get_level() * _stats.slow_power_add) * 10)

	slow_bt.apply_custom_timed(tower, event.get_target(), s, 4)
