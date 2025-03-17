extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 70, damage_add = 3.5},
		2: {damage = 250, damage_add = 12.5},
		3: {damage = 700, damage_add = 35},
		4: {damage = 1400, damage_add = 70},
		5: {damage = 2500, damage_add = 125},
}


func on_autocast(event: Event):
	var creep: Unit = event.get_target()
	tower.do_spell_damage(creep, _stats.damage + (tower.get_level() * _stats.damage_add), tower.calc_spell_crit_no_bonus())
	Effect.create_simple_at_unit("res://src/effects/monsoon_bolt.tscn", creep, Unit.BodyPart.ORIGIN)
