extends Tower

# TODO: implement visual


const _stats_map: Dictionary = {
	1: {target_count_max = 2},
	2: {target_count_max = 3},
	3: {target_count_max = 4},
	4: {target_count_max = 5},
	5: {target_count_max = 5},
}


func _ready():
	var tier: int = get_tier()
	var stats = _stats_map[tier]

	_target_count_max = stats.target_count_max
