extends Node


signal spawned(mob_name)
signal progress_changed(progress_string)
signal wave_ended(wave_index)

onready var timer: Timer = $Timer

var group_list: Array = []
var group_index: int = 0
var mob_index: int = 0
var mob_spawned_count: int = 0
var mob_total_count: int = 0

func _ready():
	start(0)

func start(wave_index: int):
	var parsed_json = Properties.waves[wave_index]
	
	if parsed_json == null || parsed_json.result == null:
		push_error("wave json file is malformed, file=wave%s.json" % wave_index)
		return
		
	group_list = parsed_json.result
	group_index = 0
	mob_index = 0
	mob_spawned_count = 0
	mob_total_count = _get_mob_total_count()
	
	if group_list.size() == 0:
		emit_signal("progress_changed", "wave is empty, do nothing")
		return
	else:
		emit_signal("progress_changed", "wave just started")
		timer.start(0)


func stop():
	timer.stop()
	
	emit_signal("progress_changed", "wave stopped")


func _get_mob_total_count() -> int:
	var out: int = 0
	
	for group in group_list:
		var mob_list: Array = group["mob_list"]
		out += mob_list.size()
	
	return out


func _on_Timer_timeout():
	var group: Dictionary = group_list[group_index]
	var time_between_mobs: float = group["time_between_mobs"]
	var mob_list: Array = group["mob_list"]
	var time_until_next_group: float = group["time_until_next_group"]
	
	var group_ended = mob_index >= mob_list.size()
	
	if group_ended:
#		Go to next group
		var wave_ended = group_index == group_list.size() - 1
		
		if wave_ended:
			emit_signal("wave_ended", group_index)
			return
		
		group_index += 1
		mob_index = 0
		timer.start(time_until_next_group)
	else:
# 		Spawn next mob
		var mob: String = mob_list[mob_index]
		mob_index += 1
		timer.start(time_between_mobs)
		
		mob_spawned_count += 1
		
		emit_signal("spawned", mob)
	
	var progress_string: String = "Group: %d/%d; Mob: %d/%d" % [group_index + 1, group_list.size(), mob_spawned_count, mob_total_count]
	
	emit_signal("progress_changed", progress_string)
