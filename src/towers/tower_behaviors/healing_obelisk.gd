extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {heal_ratio = 0.50, heal_ratio_add = 0.0040},
		2: {heal_ratio = 0.55, heal_ratio_add = 0.0052},
		3: {heal_ratio = 0.60, heal_ratio_add = 0.0068},
		4: {heal_ratio = 0.65, heal_ratio_add = 0.0080},
	}


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_level_up(on_level_up)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var loop_count: int = tower.user_int
	var healing: int = int(event.damage * (_stats.heal_ratio - tower.get_level() * _stats.heal_ratio_add))

	if !target.is_immune():
		healing = int(healing / loop_count)
		
		while true:
			if loop_count == 0:
				break

			await Utils.create_manual_timer(1.0, self).timeout

			if Utils.unit_is_valid(tower) && Utils.unit_is_valid(target):
				target.set_health(target.get_health() + healing)
				Effect.create_simple_at_unit("res://src/effects/holy_bolt.tscn", target)
				var healing_text: String = "+%d" % healing
				tower.get_player().display_floating_text_x(healing_text, target, Color8(0, 255, 0, 255), 0.05, 0.0, 2.0)
			else:
				return

			loop_count = loop_count - 1


func on_level_up(_event: Event):
	var level: int = tower.get_level()

	if level < 15:
		tower.user_int = 3
	elif level < 25:
		tower.user_int = 4
	else:
		tower.user_int = 5


func on_create(_preceding_tower: Tower):
	var level: int = tower.get_level()

	if level < 15:
		tower.user_int = 3
	elif level < 25:
		tower.user_int = 4
	else:
		tower.user_int = 5
