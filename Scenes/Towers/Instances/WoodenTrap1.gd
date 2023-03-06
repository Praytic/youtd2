extends Tower

# TODO: visual


func _get_tier_stats() -> Dictionary:
	return {
		1: {cooldown = 15, base_damage = 70, damage_add = 3, stun_duration = 0.50, max_targets = 3},
		2: {cooldown = 14, base_damage = 270, damage_add = 15, stun_duration = 0.75, max_targets = 3},
		3: {cooldown = 13, base_damage = 650, damage_add = 33, stun_duration = 1.00, max_targets = 4},
		4: {cooldown = 12, base_damage = 1500, damage_add = 75, stun_duration = 1.25, max_targets = 4},
		5: {cooldown = 11, base_damage = 2000, damage_add = 100, stun_duration = 1.50, max_targets = 5},
	}


func _tower_init():
	var triggers_buff: Buff = TriggersBuff.new()
	triggers_buff.add_periodic_event(self, "_on_periodic", 2)
	triggers_buff.apply_to_unit_permanent(self, self, 0)


func _on_periodic(event: Event):
	var tower = self
	_trap(event, tower, _stats.cooldown, _stats.base_damage, _stats.damage_add, _stats.stun_duration, _stats.max_targets)


func _trap(event: Event, tower, cooldown: float, base_damage: float, damage_add: float, stun_duration: float, max_targets: int):
	var lvl: int = tower.get_level()
	var mob_list: Array = Utils.get_mob_list_in_range(tower.position, 950)
	mob_list = Utils.shuffle_list(mob_list)
	var num_targets: int = 0

	for next in mob_list:
		num_targets = num_targets + 1
		var cb_stun: Buff = CbStun.new("cb_stun", 0, 0, false)
		cb_stun.apply_only_timed(tower, next, stun_duration)
		tower.do_spell_damage(next, base_damage + lvl * damage_add, tower.calc_spell_crit_no_bonus())
		Utils.sfx_at_unit("Abilities\\Spells\\Orc\\ReinforcedTrollBurrow\\ReinforcedTrollBurrowTarget.mdl", next)

		if num_targets >= max_targets:
			break

	if num_targets > 0:
#		Trapping successful; go into cooldown.
		event.enable_advanced(cooldown - lvl * 0.2, false)
	else:
#		Nothing trapped; go into a shorter cooldown.
		event.enable_advanced(2, false)
