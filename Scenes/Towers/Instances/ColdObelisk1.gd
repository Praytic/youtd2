extends Tower


var mc_slow: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {splash_radius = 140, slow_power = 18, slow_power_add = 0.40},
		2: {splash_radius = 180, slow_power = 24, slow_power_add = 0.45},
		3: {splash_radius = 220, slow_power = 30, slow_power_add = 0.50},
	}


func get_ability_description() -> String:
	var slow_amount: String = Utils.format_percent(_stats.slow_power * 10 * 0.001, 2)
	var slow_amount_add: String = Utils.format_percent(_stats.slow_power_add * 10 * 0.001, 2)

	var text: String = ""

	text += "[color=ORANGE]Absolute Zero[/color]\n"
	text += "The Obelisk slows creeps it damages by %s for 4 seconds.\n" % slow_amount
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s slow\n" % slow_amount_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	_set_attack_style_splash({_stats.splash_radius: 0.35})

	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.45, 0.02)


func tower_init():
	var slow: Modifier = Modifier.new()
	slow.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	mc_slow = BuffType.new("mc_slow", 0, 0, false, self)
	mc_slow.set_buff_icon("@@0@@")
	mc_slow.set_buff_modifier(slow)
	mc_slow.set_buff_tooltip("Absolute Zero\nThis unit has been frozen; it has reduced movement speed.")


func on_damage(event: Event):
	var tower: Tower = self
	var s: int = int((_stats.slow_power + tower.get_level() * _stats.slow_power_add) * 10)

	mc_slow.apply_custom_timed(tower, event.get_target(), s, 4)
