extends Tower


var velex_slow: BuffType

func _get_tier_stats() -> Dictionary:
	return {
	1: {slow_value = 0.15, chance = 0.15, chance_add = 0.0015},
	2: {slow_value = 0.18, chance = 0.12, chance_add = 0.0012},
	3: {slow_value = 0.21, chance = 0.15, chance_add = 0.0014},
	4: {slow_value = 0.24, chance = 0.16, chance_add = 0.0016},
	5: {slow_value = 0.27, chance = 0.18, chance_add = 0.0018},
}


func get_extra_tooltip_text() -> String:
	var chance: String = String.num(_stats.chance * 100, 2)
	var chance_for_bosses: String = String.num(_stats.chance * 2 / 3 * 100, 2)
	var slow_value: String = String.num(_stats.slow_value * 100, 2)
	var chance_add: String = String.num(_stats.chance_add * 100, 2)
	var chance_add_for_bosses: String = String.num(_stats.chance_add * 2 / 3 * 100, 2)

	var text: String = ""

	text += "[color=GOLD]Atrophy[/color]\n"
	text += "When this tower attacks a creep it has a %s%% (%s%% for bosses) chance to slow it by %s%% for 5 seconds.\n" % [chance, chance_for_bosses, slow_value]
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s%% (%s%% for bosses) chance" % [chance_add, chance_add_for_bosses]

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(_on_attack, 1.0, 0.0)


func tower_init():
	velex_slow = BuffType.new("velex_slow", 0, 0, false)
	var slow: Modifier = Modifier.new()
	slow.add_modification(Modification.Type.MOD_MOVESPEED, 0, -0.001)
	velex_slow.set_buff_icon("@@0@@")
	velex_slow.set_buff_modifier(slow)
	velex_slow.set_stacking_group("velex_slow1")
	
	velex_slow.set_buff_tooltip("Atrophy\nThis unit has been weaked, it has reduced move speed.")


func _on_attack(event: Event):
	var tower: Unit = self
	var creep: Unit = event.get_target()
	var size: int = creep.get_size()
	var calc: bool

	if size == CreepSize.enm.BOSS:
		calc = tower.calc_chance((_stats.chance + tower.get_level() * _stats.chance_add) * 2 / 3)
	else:
		calc = tower.calc_chance(_stats.chance + tower.get_level() * _stats.chance_add)

	if calc == true:
		

		velex_slow.apply_custom_timed(tower, event.get_target(), int(_stats.slow_value * 1000), 5.0)
