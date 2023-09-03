extends Tower


var mOck_ray_blaster: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {value = 500, value_add = 30, duration = 5},
		2: {value = 800, value_add = 35, duration = 5},
		3: {value = 1000, value_add = 40, duration = 5},
		4: {value = 1200, value_add = 45, duration = 6},
		5: {value = 1500, value_add = 50, duration = 6},
	}


func get_extra_tooltip_text() -> String:
	var value: String = Utils.format_percent(_stats.value * 0.01 * 0.01, 2)
	var value_add: String = Utils.format_percent(_stats.value_add * 0.01 * 0.01, 2)
	var duration: String = Utils.format_float(_stats.duration, 2)

	var text: String = ""

	text += "[color=GOLD]Phaze[/color]\n"
	text += "Whenever this tower damages a creep it increases its item drop chance and item drop quality by %s for %s seconds. \n" % [value, duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s item drop quality\n" % value_add
	text += "+%s item drop chance\n" % value_add
	text += "+0.1 seconds" 

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func tower_init():
	var iron_mod: Modifier = Modifier.new()
	mOck_ray_blaster = BuffType.new("mOck_ray_blaster", 0, 0, false, self)
	iron_mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_DEATH, 0.0, 0.0001)
	iron_mod.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_DEATH, 0.0, 0.0001)
	mOck_ray_blaster.set_buff_modifier(iron_mod)
	mOck_ray_blaster.set_buff_icon("@@0@@")
	mOck_ray_blaster.set_buff_tooltip("Phazed\nThis unit has be Phazed; it will drop items more often and drop items of higher quality.")


func on_damage(event: Event):
	var tower = self

	mOck_ray_blaster.apply_custom_timed(tower, event.get_target(), _stats.value + _stats.value_add * tower.get_level(), _stats.duration + tower.get_level() * 0.1)
