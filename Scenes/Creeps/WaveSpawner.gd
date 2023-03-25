extends Node


const WAVE_COUNT_EASY = 80
const WAVE_COUNT_MEDIUM = 120
const WAVE_COUNT_HARD = 240




signal wave_started(wave_number, wave_id)
signal wave_ended(wave_number, cause)


var _group_list: Array = []
var _group_index: int = 0
var _creep_index: int = 0
var _creep_spawned_count: int = 0
var _creep_total_count: int = 0
var _waves: Array = []

@onready var _timer: Timer = $Timer
@onready var item_control = get_tree().current_scene.get_node("%ItemControl")
@onready var object_ysort: Node2D = get_node("%Map").get_node("ObjectYSort")


func _ready():
	var wave_combinations_count = Properties.get_wave_csv_properties().size() - 1
	for wave_number in range(0, WAVE_COUNT_EASY):
		var wave_id = randi_range(0, wave_combinations_count)
		var wave = Wave.new(wave_id, wave_number)
		_waves.append(wave)


func wave_cleared

func start_wave(wave_number: int, wave_id: int):
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
