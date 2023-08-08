extends Node


# Spawns creeps for creep waves. Handles timing between
# creeps. Also loads creep scenes in the background to
# reduce the load time at game startup.
# 
# NOTE: Background loading may become slow if the rest of
# the game loop takes too much time. In other words if FPS
# drops too low. If a creep has to spawn before it's scene
# was loaded, then the main thread will wait for the load
# thread to finish. This will freeze the game. Watch out for
# such issues in the future. This is primarily a concern for
# the html5 target. The way to fix it: optimize perfomance
# so FPS doesn't drop too low.


signal creep_spawned(creep: Creep)
signal all_creeps_spawned


const MASS_SPAWN_DELAY_SEC = 0.2
const NORMAL_SPAWN_DELAY_SEC = 0.9
const CREEP_SCENE_INSTANCES_PATHS = {
	"HumanoidAir": "res://Scenes/Creeps/Instances/Humanoid/HumanoidAirCreep.tscn",
	"HumanoidChampion": "res://Scenes/Creeps/Instances/Humanoid/HumanoidChampionCreep.tscn",
	"HumanoidBoss": "res://Scenes/Creeps/Instances/Humanoid/HumanoidBossCreep.tscn",
	"HumanoidMass": "res://Scenes/Creeps/Instances/Humanoid/HumanoidMassCreep.tscn",
	"HumanoidNormal": "res://Scenes/Creeps/Instances/Humanoid/HumanoidNormalCreep.tscn",
	
	"OrcChampion": "res://Scenes/Creeps/Instances/Orc/OrcChampionCreep.tscn",
	"OrcAir": "res://Scenes/Creeps/Instances/Orc/OrcAirCreep.tscn",
	"OrcBoss": "res://Scenes/Creeps/Instances/Orc/OrcBossCreep.tscn",
	"OrcMass": "res://Scenes/Creeps/Instances/Orc/OrcMassCreep.tscn",
	"OrcNormal": "res://Scenes/Creeps/Instances/Orc/OrcNormalCreep.tscn",
	
	"UndeadChampion": "res://Scenes/Creeps/Instances/Undead/UndeadChampionCreep.tscn",
	"UndeadAir": "res://Scenes/Creeps/Instances/Undead/UndeadAirCreep.tscn",
	"UndeadBoss": "res://Scenes/Creeps/Instances/Undead/UndeadBossCreep.tscn",
	"UndeadMass": "res://Scenes/Creeps/Instances/Undead/UndeadMassCreep.tscn",
	"UndeadNormal": "res://Scenes/Creeps/Instances/Undead/UndeadNormalCreep.tscn",
	
	"MagicNormal": "res://Scenes/Creeps/Instances/Magic/MagicNormalCreep.tscn",
	"MagicChampion": "res://Scenes/Creeps/Instances/Magic/MagicChampionCreep.tscn",
	"MagicAir": "res://Scenes/Creeps/Instances/Magic/MagicAirCreep.tscn",
	"MagicBoss": "res://Scenes/Creeps/Instances/Magic/MagicBossCreep.tscn",
	"MagicMass": "res://Scenes/Creeps/Instances/Magic/MagicMassCreep.tscn",
	
	"NatureAir": "res://Scenes/Creeps/Instances/Nature/NatureAirCreep.tscn",
	"NatureBoss": "res://Scenes/Creeps/Instances/Nature/NatureBossCreep.tscn",
	"NatureMass": "res://Scenes/Creeps/Instances/Nature/NatureMassCreep.tscn",
	"NatureNormal": "res://Scenes/Creeps/Instances/Nature/NatureNormalCreep.tscn",
	"NatureChampion": "res://Scenes/Creeps/Instances/Nature/NatureChampionCreep.tscn",
}


# Dict[scene_name -> Resource]
var _creep_scenes: Dictionary
var _creep_spawn_queue: Array[CreepData]
var _background_load_queue: Array[String] = []
var _background_load_in_progress: bool = false

@onready var _timer_between_creeps: Timer = $Timer


func _ready():
	_timer_between_creeps.set_autostart(true)
	_timer_between_creeps.set_one_shot(false)
	
	var regex_search = RegEx.new()
	regex_search.compile("^(?!\\.).*$")


func _process(_delta: float):
	if !_background_load_queue.is_empty():
		if _background_load_in_progress:
			_process_background_load()
		else:
			_start_background_load()


# Go through all waves to get the order in which creep
# scenes are used. Need this order to do background loading
# for creep scenes in order of usage. This is to make sure
# that scenes are loaded before they need to be used to
# spawn their creeps.
func setup_background_load_queue(wave_list: Array[Wave]):
	var queue: Array[String] = []

	for wave in wave_list:
		var used_scene_list: Array[String] = wave.get_used_scene_list()

		for scene_name in used_scene_list:
			if !queue.has(scene_name):
				queue.append(scene_name)

	_background_load_queue = queue

	print_verbose("_background_load_queue = ", _background_load_queue)


func _start_background_load():
	var scene_name: String = _background_load_queue.front()
	var scene_path: String = CREEP_SCENE_INSTANCES_PATHS[scene_name]
	ResourceLoader.load_threaded_request(scene_path, "", false)
	_background_load_in_progress = true

	print_verbose("Starting to load creep scene: ", scene_name)
	ElapsedTimer.start("Elapsed time for loading creep scene:" + scene_name)


func _process_background_load():
	var scene_name: String = _background_load_queue.front()
	var scene_path: String = CREEP_SCENE_INSTANCES_PATHS[scene_name]

	var finished: bool = ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED

	if finished:
		var scene: PackedScene = ResourceLoader.load_threaded_get(scene_path)
		_creep_scenes[scene_name] = scene
		_background_load_queue.pop_front()
		_background_load_in_progress = false

		print_verbose("Finished loading creep scene: ", scene_name)
		ElapsedTimer.end_verbose("Elapsed time for loading creep scene:" + scene_name)


# Waits until creep scene is done loading
func _wait_for_background_load(scene_name: String):
	var scene_path: String = CREEP_SCENE_INSTANCES_PATHS[scene_name]

	var scene: PackedScene = ResourceLoader.load_threaded_get(scene_path)
	_creep_scenes[scene_name] = scene
	_background_load_queue.pop_front()
	_background_load_in_progress = false


func queue_spawn_creep(creep_data: CreepData):
	assert(creep_data != null, "Tried to spawn null creep.")

	var is_mass: bool = creep_data.size == CreepSize.enm.MASS || creep_data.size == CreepSize.enm.CHALLENGE_MASS
	
	_creep_spawn_queue.push_back(creep_data)
	if _timer_between_creeps.is_stopped():
		if is_mass:
			_timer_between_creeps.set_wait_time(MASS_SPAWN_DELAY_SEC)
		elif creep_data.size == CreepSize.enm.NORMAL:
			_timer_between_creeps.set_wait_time(NORMAL_SPAWN_DELAY_SEC)
		print_verbose("Start creep spawn timer with delay [%s]." % _timer_between_creeps.get_wait_time())
		_timer_between_creeps.start()


func spawn_creep(creep_data: CreepData) -> Creep:
	var creep_size: CreepSize.enm = creep_data.size
	var creep_scene_name: String = creep_data.scene_name
	var wave: Wave = creep_data.wave

# 	NOTE: if creep needs to spawn and it's scene didn't
# 	finish loading in the background yet, then we'll need to
# 	wait for the creep scene to load. This will freeze the
# 	game. Should only happen if the player starts the first
# 	wave immediately after game starts.
	var scene_not_loaded: bool = !_creep_scenes.has(creep_scene_name)

	if scene_not_loaded:
		print_verbose("Creep spawned too early. Waiting for loading of creep scene to finish: ", creep_scene_name)
		_wait_for_background_load(creep_scene_name)

	var creep = _creep_scenes[creep_scene_name].instantiate()

	if creep == null:
		push_error("Could not find a scene for creep size [%s] and race [%]." % [creep_size, wave.get_race()])

		return null

	var creep_armor: float = wave.get_base_armor()

	var size_multiplier: float = CreepSize.health_multiplier_map[creep_size]
	var creep_health: float = wave.get_base_hp() * size_multiplier

	creep.set_path(wave.get_wave_path())
	creep.set_creep_size(creep_size)
	creep.set_armor_type(wave.get_armor_type())
	creep.set_category(wave.get_race())
	creep.set_base_health(creep_health)
	creep.set_base_armor(creep_armor)
	creep.set_spawn_level(wave.get_level())

	wave.add_alive_creep(creep)

	Utils.add_object_to_world(creep)
	print_verbose("Creep has been spawned [%s]." % creep)

#	NOTE: buffs must be applied after creep has been added to
#	world
	var special_list: Array[int] = wave.get_specials()
	WaveSpecial.apply_to_creep(special_list, creep)

	return creep


func _on_Timer_timeout():
	if _creep_spawn_queue.is_empty():
		print_verbose("Stop creep spawn. Queue is exhausted.")
		_timer_between_creeps.stop()
		all_creeps_spawned.emit()

		return

	var creep_data: CreepData = _creep_spawn_queue.pop_front()

	var creep: Creep = spawn_creep(creep_data)
	creep_spawned.emit(creep)
