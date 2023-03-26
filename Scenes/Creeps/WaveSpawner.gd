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
@onready var _creep_spawner = $CreepSpawner

func _ready():
	var wave_combinations_count = Properties.get_wave_csv_properties().size() - 1
	for wave_number in range(0, WAVE_COUNT_EASY):
		var wave_id = randi_range(0, wave_combinations_count)
		var wave_race = randi_range(0, Creep.Category.size())
		var wave_armor = randi_range(0, ArmorType.enm.size())
		
		var wave = Wave.new()
		wave.set_id(wave_id)
		wave.set_wave_number(wave_number)
		wave.set_race(wave_race)
		wave.set_armor_type(wave_armor)
		
		_waves.append(wave)


func spawn_wave(wave: Wave):
	for creep_size in wave.get_creeps_combination():
		var creep = Creep.new()
		creep.set_path_curve(wave.get_path())
		creep.set_creep_size(creep_size)
		creep.set_armor_type(wave.get_armor_type())
		creep.set_category(wave.get_race)
		_creeps.append(creep)


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
