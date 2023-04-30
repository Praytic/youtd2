extends Tower


func _get_tier_stats() -> Dictionary:
	return {
		1: {on_damage_chance = 0.10, damage_add = 0.01},
		2: {on_damage_chance = 0.11, damage_add = 0.02},
		3: {on_damage_chance = 0.12, damage_add = 0.03},
		4: {on_damage_chance = 0.13, damage_add = 0.04},
		5: {on_damage_chance = 0.14, damage_add = 0.05},
}


func get_extra_tooltip_text() -> String:
	var on_damage_chance: String = String.num(_stats.on_damage_chance * 100, 2)
	var damage_add: String = String.num(_stats.damage_add, 2)

	var text: String = ""

	text += "[color=gold]Frozen Spears[/color]\n"
	text += "Has a %s%% chance to deal 50%% more damage and stun the target for 0.5 seconds.\n" % on_damage_chance
	text += "[color=orange]Level Bonus:[/color]\n"
	text += "+%s%% damage\n" % damage_add
	text += "+0.01 seconds"

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(self, "on_damage", 0.1, 0.0)


func on_damage(event: Event):
	var tower: Tower = self

	var creep: Unit = event.get_target()
	var level: float = tower.get_level()

	if event.is_main_target():
		event.damage = event.damage * (1.5 + (0.01 * level))
		Utils.sfx_at_unit("Objects\\Spawnmodels\\Critters\\Albatross\\CritterBloodAlbatross.mdl", creep)
		var cb_stun: BuffType = CbStun.new("cb_stun", 1.0, 0, false)
		cb_stun.apply_only_timed(tower, creep, 0.5 + tower.get_level() * 0.01)
		tower.getOwner().display_small_floating_text(str(int(event.damage)), tower, 255, 150, 150, 0)
