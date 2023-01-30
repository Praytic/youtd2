extends Node


signal spawned(mob_name)
signal progress_changed(progress_string)
signal wave_ended(wave_index)

var _group_list: Array = []
var _group_index: int = 0
var _mob_index: int = 0
var _mob_spawned_count: int = 0
var _mob_total_count: int = 0

onready var _timer: Timer = $Timer


func _ready():
	start(0)


func start(wave_index: int):
	var parsed_json = Properties.waves[wave_index]
	
	if parsed_json == null || parsed_json.result == null:
		push_error("wave json file is malformed, file=wave%s.json" % wave_index)
		return
		
	_group_list = parsed_json.result
	_group_index = 0
	_mob_index = 0
	_mob_spawned_count = 0
	_mob_total_count = _get__mob_total_count()
	
	if _group_list.size() == 0:
		emit_signal("progress_changed", "wave is empty, do nothing")
		return
	else:
		emit_signal("progress_changed", "wave just started")
		_timer.start(0)


func stop():
	_timer.stop()
	
	emit_signal("progress_changed", "wave stopped")


func _get__mob_total_count() -> int:
	var out: int = 0
	
	for group in _group_list:
		var mob_list: Array = group["mob_list"]
		out += mob_list.size()
	
	return out


func _on_Timer_timeout():
	var group: Dictionary = _group_list[_group_index]
	var time_between_mobs: float = group["time_between_mobs"]
	var mob_list: Array = group["mob_list"]
	var time_until_next_group: float = group["time_until_next_group"]
	
	var group_ended = _mob_index >= mob_list.size()
	
	if group_ended:
#		Go to next group
		var wave_ended = _group_index == _group_list.size() - 1
		
		if wave_ended:
			emit_signal("wave_ended", _group_index)
			return
		
		_group_index += 1
		_mob_index = 0
		_timer.start(time_until_next_group)
	else:
# 		Spawn next mob
		var mob: String = mob_list[_mob_index]
		_mob_index += 1
		_timer.start(time_between_mobs)
		
		_mob_spawned_count += 1
		
		emit_signal("spawned", mob)
	
	var progress_string: String = "Group: %d/%d; Mob: %d/%d" % [_group_index + 1, _group_list.size(), _mob_spawned_count, _mob_total_count]
	
	emit_signal("progress_changed", progress_string)
