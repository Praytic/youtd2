extends Tower


var cb_stun: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {cooldown = 15, base_damage = 70, damage_add = 3, stun_duration = 0.50, max_targets = 3},
		2: {cooldown = 14, base_damage = 270, damage_add = 15, stun_duration = 0.75, max_targets = 3},
		3: {cooldown = 13, base_damage = 650, damage_add = 33, stun_duration = 1.00, max_targets = 4},
		4: {cooldown = 12, base_damage = 1500, damage_add = 75, stun_duration = 1.25, max_targets = 4},
		5: {cooldown = 11, base_damage = 2000, damage_add = 100, stun_duration = 1.50, max_targets = 5},
	}


func get_extra_tooltip_text() -> String:
	var cooldown: String = Utils.format_float(_stats.cooldown, 2)
	var max_targets: String = Utils.format_float(_stats.max_targets, 2)
	var base_damage: String = Utils.format_float(_stats.base_damage, 2)
	var damage_add: String = Utils.format_float(_stats.damage_add, 2)
	var stun_duration: String = Utils.format_float(_stats.stun_duration, 2)

	var text: String = ""

	text += "[color=GOLD]Activate Trap[/color]\n"
	text += "Every %s seconds this tower traps %s creeps in 950 range, dealing %s spelldamage and stunning them for %s seconds.\n" % [cooldown, max_targets, base_damage, stun_duration]
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spelldamage\n" % damage_add
	text += "-0.2 seconds cooldown"

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_periodic_event(on_periodic, 2)


func tower_init():
	cb_stun = CbStun.new("cb_stun", 0, 0, false, self)


func on_periodic(event: Event):
	var tower = self
	trap(event, tower, _stats.cooldown, _stats.base_damage, _stats.damage_add, _stats.stun_duration, _stats.max_targets)


func trap(event: Event, tower, cooldown: float, base_damage: float, damage_add: float, stun_duration: float, max_targets: int):
	var lvl: int = tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 950)
	var next: Unit = it.next_random()
	var num_targets: int = 0

	while true:
		if next == null:
			break
		num_targets = num_targets + 1
		cb_stun.apply_only_timed(tower, next, stun_duration)
		tower.do_spell_damage(next, base_damage + lvl * damage_add, tower.calc_spell_crit_no_bonus())
		SFX.sfx_at_unit("Abilities\\Spells\\Orc\\ReinforcedTrollBurrow\\ReinforcedTrollBurrowTarget.mdl", next)

		if num_targets >= max_targets:
			break

		next = it.next_random()

	if next != null:
		it.destroy()

	if num_targets > 0:
#		Trapping successful; go into cooldown.
		event.enable_advanced(cooldown - lvl * 0.2, false)
	else:
#		Nothing trapped; go into a shorter cooldown.
		event.enable_advanced(2, false)
