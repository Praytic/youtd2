extends Tower


var mOck_ray_blaster: BuffType


func _get_tier_stats() -> Dictionary:
	return {
		1: {value = 500, value_add = 30, duration = 5},
		2: {value = 800, value_add = 35, duration = 5},
		3: {value = 1000, value_add = 40, duration = 5},
		4: {value = 1200, value_add = 45, duration = 6},
		5: {value = 1500, value_add = 50, duration = 6},
	}


func get_extra_tooltip_text() -> String:
	var value: String = String.num(_stats.value / 100.0, 2)
	var value_add: String = String.num(_stats.value_add / 100.0, 2)
	var duration: String = String.num(_stats.duration * 100, 2)

	return "[color=gold]Phaze[/color]\nWhenever this tower damages a creep it increases its item drop chance and item drop quality by %s%% for %s seconds. \n[color=orange]Level Bonus:[/color]\n+%s%% item drop quality\n+%s%% item drop chance\n+0.1 seconds" % [value, duration, value_add, value_add]


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(self, "on_damage", 1.0, 0.0)


func tower_init():
	var iron_mod: Modifier = Modifier.new()
	mOck_ray_blaster = BuffType.new("mOck_ray_blaster", 0, 0, false)
	iron_mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_DEATH, 0.0, 0.0001)
	iron_mod.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_DEATH, 0.0, 0.0001)
	mOck_ray_blaster.set_buff_modifier(iron_mod)
	mOck_ray_blaster.set_buff_icon("@@0@@")
	mOck_ray_blaster.set_buff_tooltip("Phazed\nThis unit has increased item drop chance and item drop quality.")


func on_damage(event: Event):
	var tower = self

	mOck_ray_blaster.apply_custom_timed(tower, event.get_target(), _stats.value + _stats.value_add * tower.get_level(), _stats.duration + tower.get_level() * 0.1)
