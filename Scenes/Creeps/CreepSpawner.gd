extends Node


signal creep_spawned(creep: Creep)
signal all_creeps_spawned


const MASS_SPAWN_DELAY_SEC = 0.2
const NORMAL_SPAWN_DELAY_SEC = 0.9
const CREEP_SCENE_INSTANCES_PATH = "res://Scenes/Creeps/Instances/"


# Dict[scene_name -> Resource]
var _creep_scenes: Dictionary
var _creep_spawn_queue: Array

@onready var item_control = get_tree().current_scene.get_node("%ItemControl")
@onready var object_ysort: Node2D = get_tree().current_scene.get_node("%Map/ObjectYSort")
@onready var _timer_between_creeps: Timer = $Timer


func _ready():
	_timer_between_creeps.set_autostart(true)
	_timer_between_creeps.set_one_shot(false)
	
	# Load resources of creep scenes for each combination
	# of Creep.Size and Creep.Category
	var creep_scenes = Utils.list_files_in_directory(CREEP_SCENE_INSTANCES_PATH)
	for creep_scene_path in creep_scenes:
		var creep_scene_name = creep_scene_path.substr(0, creep_scene_path.length() - 5)
		var preloaded_creep_scene = load(CREEP_SCENE_INSTANCES_PATH + creep_scene_path)
		_creep_scenes[creep_scene_name] = preloaded_creep_scene
	
	print("Creep scenes have been loaded.")


func spawn_creep(creep: Creep):
	_creep_spawn_queue.push_back(creep)
	if _timer_between_creeps.is_stopped():
		if creep.get_creep_size() == Creep.Size.MASS:
			_timer_between_creeps.set_wait_time(MASS_SPAWN_DELAY_SEC)
		elif creep.get_creep_size() == Creep.Size.NORMAL:
			_timer_between_creeps.set_wait_time(NORMAL_SPAWN_DELAY_SEC)
		print_debug("Start creep spawn timer with delay [%s]." % _timer_between_creeps.get_wait_time())
		_timer_between_creeps.start()


func generate_creep_for_wave(wave: Wave, creep_size) -> Creep:
	var creep_size_name = Utils.screaming_snake_case_to_camel_case(Creep.Size.keys()[creep_size])
	var creep_race_name = Utils.screaming_snake_case_to_camel_case(Creep.Category.keys()[wave.get_race()])
	var creep_scene_name = creep_race_name + creep_size_name
	var creep = _creep_scenes[creep_scene_name].instantiate()
	if not creep:
		push_error("Could not find a scene for creep size [%s] and race [%]." % [creep_size, wave.get_race()])
	creep.set_path(wave.get_wave_path())
	creep.set_creep_size(creep_size)
	creep.set_armor_type(wave.get_armor_type())
	creep.set_category(wave.get_race())
	creep.set_base_health(wave.get_base_hp())
	creep.death.connect(Callable(wave, "_on_Creep_death"))
	return creep


func _on_Timer_timeout():
	var creep = _creep_spawn_queue.pop_front()
	if not creep:
		print_debug("Stop creep spawn. Queue is exhausted.")
		_timer_between_creeps.stop()
		all_creeps_spawned.emit()
		return
	
	creep.death.connect(Callable(item_control, "_on_Creep_death"))
	object_ysort.add_child(creep, true)
	print_debug("Creep has been spawned [%s]." % creep)
	creep_spawned.emit(creep)
