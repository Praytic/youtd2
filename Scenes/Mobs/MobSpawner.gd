extends Node


signal spawned(mob_name)
signal progress_changed(progress_string)
signal wave_ended(wave_index)

const mob_scene_map: Dictionary = {
	"Mob": preload("res://Scenes/Mobs/Mob.tscn")
}

var _group_list: Array = []
var _group_index: int = 0
var _mob_index: int = 0
var _mob_spawned_count: int = 0
var _mob_total_count: int = 0

@onready var _timer: Timer = $Timer
@onready var item_control = get_tree().current_scene.get_node("%ItemControl")
@onready var mob_ysort: Node2D = get_node("%Map").get_node("MobYSort")
@onready var mob_path: Node2D = get_node("%Map").get_node("MobPath1")

func _ready():
	start(0)


func start(wave_index: int):
	var parsed_json = Properties.waves[wave_index]
	
	if parsed_json == null:
		push_error("wave json file is malformed, file=wave%s.json" % wave_index)
		return
		
	_group_list = parsed_json
	_group_index = 0
	_mob_index = 0
	_mob_spawned_count = 0
	_mob_total_count = _get__mob_total_count()
	
	if _group_list.size() == 0:
		progress_changed.emit("wave is empty, do nothing")
		return
	else:
		progress_changed.emit("wave just started")
		_timer.start(0)


func stop():
	_timer.stop()
	
	progress_changed.emit("wave stopped")


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
		var wave_is_over = _group_index == _group_list.size() - 1
		
		if wave_is_over:
			wave_ended.emit(_group_index)
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
		
		var mob_scene: Mob = mob_scene_map[mob].instantiate()
		mob_scene.set_path(mob_path)
		mob_ysort.add_child(mob_scene)
		mob_scene.death.connect(Callable(item_control, "_on_Mob_death"))
		spawned.emit(mob)
	
	var progress_string: String = "Group: %d/%d; Mob: %d/%d" % [_group_index + 1, _group_list.size(), _mob_spawned_count, _mob_total_count]
	
	progress_changed.emit(progress_string)
