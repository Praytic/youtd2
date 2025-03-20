extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 60, damage_add = 3},
		2: {damage = 215, damage_add = 11},
		3: {damage = 600, damage_add = 30},
		4: {damage = 1200, damage_add = 60},
		5: {damage = 2150, damage_add = 107},
}


func on_autocast(event: Event):
	Effect.create_simple_at_unit("res://src/effects/firelord_death_explode.tscn", event.get_target())
	tower.do_spell_damage_aoe_unit(event.get_target(), 200, _stats.damage + _stats.damage_add * tower.get_level(), tower.calc_spell_crit_no_bonus(), 0.0)
