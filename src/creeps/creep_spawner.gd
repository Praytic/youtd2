class_name CreepSpawner extends Node


# Spawns creeps for creep waves.


signal creep_spawned(creep: Creep)
signal all_creeps_spawned


# NOTE: the values for champion and boss are unused because
# waves with champions use delay of the main creep size
# while bosses are alone in their waves and have no creeps
# after them. This is intended behavior.
const _creep_delay_map: Dictionary = {
	CreepSize.enm.MASS: [0.15, 0.4],
	CreepSize.enm.NORMAL: [0.4, 2.2],
	CreepSize.enm.AIR: [1.0, 3.0],
	CreepSize.enm.CHAMPION: [0.7, 4.4],
	CreepSize.enm.BOSS: [1.5, 9.0],
	CreepSize.enm.CHALLENGE_MASS: [0.15, 0.4],
	CreepSize.enm.CHALLENGE_BOSS: [1.5, 9.0],
}


var _player: Player = null
var _ground_path: WavePath = null
var _air_path: WavePath = null
var _wave_queue: Array[Wave] = []
var _current_wave: Wave
var _creep_index: int = 0

@export var _timer_between_creeps: ManualTimer


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


# NOTE: need to save wave to queue in case another wave is
# in progress so that current wave is properly finished.
# Note that such behavior can only arise due to a bug -
# normal behavior is that waves started after previous wave
# is finished. One possible source of such a bug is the auto
# wave timer on extreme difficulty (if auto delay is less
# than the total sum of delays between creeps of current
# wave).
func start_spawning_wave(wave: Wave):
	var wave_is_in_progress: bool = _current_wave != null

	if !wave_is_in_progress:
		_current_wave = wave
		_creep_index = 0
		_spawn_next_creep()
	else:
		_wave_queue.push_back(wave)


#########################
###      Private      ###
#########################

func _spawn_next_creep():
	var creep_combination: Array[CreepSize.enm] = _current_wave.get_creep_combination()
	var creep_size: CreepSize.enm = creep_combination[_creep_index]
	var creep_race: CreepCategory.enm = _current_wave.get_creep_race()
	var creep_armor: float = _current_wave.get_base_armor()
	var creep_armor_type: ArmorType.enm = _current_wave.get_armor_type()
	var creep_level: int = _current_wave.get_level()
	var creep_health: float = CreepSpawner.get_creep_health(_current_wave, creep_size)
	var creep_specials: Array[int] = _current_wave.get_specials()
	var creep_path: WavePath = get_creep_path(creep_size)
	var creep_scene_name: String = Wave.get_scene_name_for_creep_type(creep_size, creep_race)
	
	if !Preloads.creep_scenes.has(creep_scene_name):
		push_error("Could not find a scene for creep size [%s] and race [%]." % [creep_size, creep_race])

		return

	var creep_scene: PackedScene = Preloads.creep_scenes[creep_scene_name]
	var creep: Creep = creep_scene.instantiate()
	creep.set_path(creep_path)
	creep.set_player(_player)
	creep.set_creep_size(creep_size)
	creep.set_armor_type(creep_armor_type)
	creep.set_category(creep_race)
	creep.set_base_health(creep_health)
	creep.set_health(creep_health)
	creep.set_base_armor(creep_armor)
	creep.set_spawn_level(creep_level)

	_current_wave.add_alive_creep(creep)

	Utils.add_object_to_world(creep)
	print_verbose("Spawned creep [%s]." % creep)

#	NOTE: buffs must be applied after creep has been added
#	to world
	WaveSpecial.apply_to_creep(creep_specials, creep)
	
	_creep_index += 1
	
	var creep_count: int = _current_wave.get_creep_count()
	var spawned_all_creeps: bool = _creep_index >= creep_count
	
	if spawned_all_creeps:
		print_verbose("Finished spawning creeps for current wave.")
		
		all_creeps_spawned.emit()

		if !_wave_queue.is_empty():
			_current_wave = _wave_queue.pop_front()
		else:
			_current_wave = null

		_creep_index = 0
	else:
#		NOTE: need to calculate delay based on the main
#		creep size of the way, NOT the creep size of the
#		current creep. This is important for mass+champ or
#		normal+champ waves having appropriate spacing.
		var wave_main_creep_size: CreepSize.enm = _current_wave.get_creep_size()
		var delay_before_next_creep: float = CreepSpawner.get_creep_delay(wave_main_creep_size)
		_timer_between_creeps.start(delay_before_next_creep)
		print_verbose("Started creep spawn timer with delay [%f]." % delay_before_next_creep)


func get_creep_path(creep_size: CreepSize.enm) -> Path2D:
	if creep_size == CreepSize.enm.AIR:
		return _air_path
	else:
		return _ground_path


#########################
###     Callbacks     ###
#########################

func _on_spawn_timer_timeout():
	_spawn_next_creep()


func _on_game_over():
	_timer_between_creeps.stop()


#########################
###       Static      ###
#########################

static func get_creep_health(wave: Wave, creep_size: CreepSize.enm) -> float:
	var size_multiplier: float = CreepSize.health_multiplier_map[creep_size]
	var creep_health: float = wave.get_base_hp() * size_multiplier

	return creep_health


static func get_creep_delay(wave_main_creep_size: CreepSize.enm) -> float:
	var delay_range: Array = _creep_delay_map[wave_main_creep_size]
	var delay_min: float = delay_range[0]
	var delay_max: float = delay_range[1]
	var creep_delay: float = Globals.synced_rng.randf_range(delay_min, delay_max)
	
	return creep_delay
