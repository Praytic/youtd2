class_name CreepSpawner extends Node


# Spawns creeps for creep waves.


signal creep_spawned(creep: Creep)
signal all_creeps_spawned


const MASS_SPAWN_DELAY_SEC = 0.2
const NORMAL_SPAWN_DELAY_SEC = 0.9


var _creep_spawn_queue: Array[CreepData]
var _player: Player = null
var _ground_path: WavePath = null
var _air_path: WavePath = null

@export var _timer_between_creeps: ManualTimer


#########################
###     Built-in      ###
#########################

func _ready():
	_timer_between_creeps.set_autostart(true)
	_timer_between_creeps.set_one_shot(false)
	

#########################
###       Public      ###
#########################

func set_player(player: Player):
	_player = player

	_player.get_team().game_over.connect(_on_game_over)

	_ground_path = Utils.find_creep_path(player, false)
	_air_path = Utils.find_creep_path(player, true)

	if _air_path == null || _ground_path == null:
		push_error("Failed to find paths for player %d, player index %d" % [player.get_id(), player.get_index()])


func queue_spawn_creep(creep_data: CreepData):
	assert(creep_data != null, "Tried to spawn null creep.")

	var wave: Wave = creep_data.wave
	var wave_size: CreepSize.enm = wave.get_creep_size()
	var wave_is_mass: bool = wave_size == CreepSize.enm.MASS || wave_size == CreepSize.enm.CHALLENGE_MASS
	
	_creep_spawn_queue.push_back(creep_data)
	if _timer_between_creeps.is_stopped():
		if wave_is_mass:
			_timer_between_creeps.set_wait_time(MASS_SPAWN_DELAY_SEC)
		else:
			_timer_between_creeps.set_wait_time(NORMAL_SPAWN_DELAY_SEC)
		print_verbose("Start creep spawn timer with delay [%s]." % _timer_between_creeps.get_wait_time())
		_timer_between_creeps.start()


func spawn_creep(creep_data: CreepData) -> Creep:
	var creep_size: CreepSize.enm = creep_data.size
	var creep_scene_name: String = creep_data.scene_name
	var wave: Wave = creep_data.wave

	if !Preloads.creep_scenes.has(creep_scene_name):
		push_error("Could not find a scene for creep size [%s] and race [%]." % [creep_size, wave.get_race()])

		return null

	var creep_scene: PackedScene = Preloads.creep_scenes[creep_scene_name]
	var creep: Creep = creep_scene.instantiate()

	var creep_armor: float = wave.get_base_armor()

	var creep_health: float = CreepSpawner.get_creep_health(wave, creep_size)

	var path: WavePath
	if creep_size == CreepSize.enm.AIR:
		path = _air_path
	else:
		path = _ground_path
	creep.set_path(path)

	creep.set_player(_player)
	creep.set_creep_size(creep_size)
	creep.set_armor_type(wave.get_armor_type())
	creep.set_category(wave.get_race())
	creep.set_base_health(creep_health)
	creep.set_health(creep_health)
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


#########################
###     Callbacks     ###
#########################

func _on_Timer_timeout():
	if _creep_spawn_queue.is_empty():
		push_error("Creep spawn queue is empty during first timeout. This should never happen.")

		return

	var creep_data: CreepData = _creep_spawn_queue.pop_front()

	var creep: Creep = spawn_creep(creep_data)
	creep_spawned.emit(creep)

#	NOTE: it's important to check this at the end of timeout
#	handler. If this is checked at the start then there will
#	be a time delay between the last creep spawning and
#	emission of all_creeps_spawned signal. This causes bugs
#	when creep is killed during that delay.
	if _creep_spawn_queue.is_empty():
		print_verbose("Stop creep spawn. Queue is exhausted.")
		_timer_between_creeps.stop()
		all_creeps_spawned.emit()


func _on_game_over():
	_timer_between_creeps.stop()


#########################
###       Static      ###
#########################


static func get_creep_health(wave: Wave, creep_size: CreepSize.enm) -> float:
	var size_multiplier: float = CreepSize.health_multiplier_map[creep_size]
	var creep_health: float = wave.get_base_hp() * size_multiplier

	return creep_health
