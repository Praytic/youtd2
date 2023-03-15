extends Node


signal spawned(creep_name)
signal progress_changed(progress_string)
signal wave_ended(wave_index)

const creep_scene_map: Dictionary = {
	"Creep": preload("res://Scenes/Creeps/Creep.tscn")
}

var _group_list: Array = []
var _group_index: int = 0
var _creep_index: int = 0
var _creep_spawned_count: int = 0
var _creep_total_count: int = 0

@onready var _timer: Timer = $Timer
@onready var item_control = get_tree().current_scene.get_node("%ItemControl")
@onready var object_ysort: Node2D = get_node("%Map").get_node("ObjectYSort")
@onready var creep_path: Node2D = get_node("%Map").get_node("CreepPath1")

func _ready():
	start(0)


func start(wave_index: int):
	var parsed_json = Properties.waves[wave_index]
	
	if parsed_json == null:
		push_error("wave json file is malformed, file=wave%s.json" % wave_index)
		return
		
	_group_list = parsed_json
	_group_index = 0
	_creep_index = 0
	_creep_spawned_count = 0
	_creep_total_count = _get__creep_total_count()
	
	if _group_list.size() == 0:
		progress_changed.emit("wave is empty, do nothing")
		return
	else:
		progress_changed.emit("wave just started")
		_timer.start(0)


func stop():
	_timer.stop()
	
	progress_changed.emit("wave stopped")


func _get__creep_total_count() -> int:
	var out: int = 0
	
	for group in _group_list:
		var creep_list: Array = group["creep_list"]
		out += creep_list.size()
	
	return out


func _on_Timer_timeout():
	var group: Dictionary = _group_list[_group_index]
	var time_between_creeps: float = group["time_between_creeps"]
	var creep_list: Array = group["creep_list"]
	var time_until_next_group: float = group["time_until_next_group"]
	
	var group_ended = _creep_index >= creep_list.size()
	
	if group_ended:
#		Go to next group
		var wave_is_over = _group_index == _group_list.size() - 1
		
		if wave_is_over:
			wave_ended.emit(_group_index)
			return
		
		_group_index += 1
		_creep_index = 0
		_timer.start(time_until_next_group)
	else:
# 		Spawn next creep
		var creep: String = creep_list[_creep_index]
		_creep_index += 1
		_timer.start(time_between_creeps)
		
		_creep_spawned_count += 1
		
		var creep_scene: Creep = creep_scene_map[creep].instantiate()
		creep_scene.set_path(creep_path)
		object_ysort.add_child(creep_scene)
		creep_scene.death.connect(Callable(item_control, "_on_Creep_death"))
		spawned.emit(creep)
	
	var progress_string: String = "Group: %d/%d; Creep: %d/%d" % [_group_index + 1, _group_list.size(), _creep_spawned_count, _creep_total_count]
	
	progress_changed.emit(progress_string)
