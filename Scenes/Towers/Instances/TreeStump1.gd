extends Tower

# TODO: implement visual


func _get_tier_stats() -> Dictionary:
	return {
		1: {target_count_max = 2},
		2: {target_count_max = 3},
		3: {target_count_max = 4},
		4: {target_count_max = 5},
		5: {target_count_max = 5},
	}


func tower_init():
	_set_target_count(_stats.target_count_max)
