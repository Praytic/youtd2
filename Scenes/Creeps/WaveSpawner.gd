class_name WaveSpawner extends Node


const WAVE_COUNT_EASY = 80
const WAVE_COUNT_MEDIUM = 120
const WAVE_COUNT_HARD = 240
var TIME_BETWEEN_WAVES: float = 15.0


signal wave_started(wave: Wave)
signal wave_spawned(wave: Wave)
signal wave_ended(wave: Wave)
signal all_waves_cleared


var _wave_list: Array[Wave] = []

@onready var _timer_between_waves: Timer = $Timer
@onready var _creep_spawner = $CreepSpawner
@onready var _wave_paths = get_tree().get_nodes_in_group("wave_path")

func _ready():
	if FF.fast_waves_enabled():
		TIME_BETWEEN_WAVES = 0.1

	_timer_between_waves.set_autostart(false)
	_timer_between_waves.set_wait_time(TIME_BETWEEN_WAVES)
	
	var previous_wave = null
	for wave_number in range(1, WAVE_COUNT_EASY):
		var wave_id = randi_range(0, Properties.get_wave_csv_properties().size() - 1)
		var wave_race = randi_range(0, CreepCategory.enm.size() - 1)
		var wave_armor = randi_range(0, ArmorType.enm.size() - 1)
		
		var wave = Wave.new()
		wave.set_id(wave_id)
		wave.set_wave_number(wave_number)
		wave.set_race(wave_race)
		wave.set_armor_type(wave_armor)
		wave.set_wave_path(_get_wave_path(0, wave))
		
		var creep_combination = []
		for creep_size in wave.get_creeps_combination():
			var creep_size_name: String = CreepSize.convert_to_string(creep_size)
			creep_combination.append(creep_size_name)
		
		_init_wave_creeps(wave)
		
		print_verbose("Wave number [%s] will have creeps [%s] of race [%s] and armor type [%s]" \
			% [wave_number, \
				", ".join(creep_combination), \
				CreepCategory.convert_to_string(wave_race), \
				ArmorType.convert_to_string(wave_armor)])
		
		if previous_wave:
			previous_wave.next_wave = wave
		previous_wave = wave
		if wave_number == 1:
			wave.add_to_group("current_wave")
		wave.add_to_group("wave")

		_wave_list.append(wave)
		
		wave.wave_ended.connect(Callable(self, "_on_Wave_ended"))
 
		add_child(wave, true)
	
	print_verbose("Waves have been initialized. Total waves: %s" % get_waves().size())
	
	_timer_between_waves.start()


func spawn_wave(new_wave: Wave):
	new_wave.state = Wave.State.SPAWNING

	WaveLevel.increment()
	
	for creep in new_wave.get_creeps():
		_creep_spawner.queue_spawn_creep(creep)


func _init_wave_creeps(wave: Wave):
	var creeps = []
	var creep_sizes = wave.get_creeps_combination()
	for creep_size in creep_sizes:
		var creep = _creep_spawner.generate_creep_for_wave(wave, creep_size)
		creeps.append(creep)
		
	wave.set_creeps(creeps)

func end_current_wave():
	var current_wave = get_current_wave()
	
	print_verbose("Wave has ended [%s]." % current_wave)
	
	# Send events, restart the timer
	if get_waves().is_empty():
		all_waves_cleared.emit()
	else:
		_timer_between_waves.start()
		wave_ended.emit(current_wave)
	
	# Prepare variables for the next wave
	var next_wave = current_wave.next_wave
	current_wave.remove_from_group("current_wave")
	next_wave.add_to_group("current_wave")


func _on_Timer_timeout():
	_start_next_wave()


func _start_next_wave():
	var current_wave = get_current_wave()
	
	spawn_wave(current_wave)
	
	print_verbose("Wave has started [%s]." % current_wave)
	wave_started.emit(current_wave)


func _get_wave_path(player: int, wave: Wave) -> Path2D:
	var idx = -1
	for i in _wave_paths.size():
		var wave_path = _wave_paths[i]
		if wave_path.is_air == wave.is_air() \
				and wave_path.player == player:
			idx = i
			break
	
	if idx == -1:
		push_error("Could not find wave path for player [%s] and wave [%s] in "  % [player, wave] \
			+ "a group of paths [wave_path].")
	return _wave_paths[idx]


func _on_CreepSpawner_all_creeps_spawned():
	var current_wave = get_current_wave()
	current_wave.state = Wave.State.SPAWNED
	print_verbose("Wave has been spawned [%s]." % current_wave)
	wave_spawned.emit(current_wave)


func get_current_wave() -> Wave:
	return get_tree().get_first_node_in_group("current_wave")


func get_waves() -> Array:
	return get_tree().get_nodes_in_group("wave")


# NOTE: use _wave_list instead of get_waves() because
# get_waves() uses get_nodes_in_group() which is not
# ordered.
func get_wave(level: int) -> Wave:
	var index: int = level - 1

	var in_bounds: bool = 0 <= index && index < _wave_list.size()

	if in_bounds:
		var wave: Wave = _wave_list[index]

		return wave
	else:
		return null


# TODO: Fix this f-n so that it returns time until next
# wave. Currently it returns non-zero time only after creeps
# exit the portal.
func get_time_left() -> float:
	var time: float = _timer_between_waves.get_time_left()

	return time


func wave_is_in_progress() -> float:
	var out: bool = _timer_between_waves.is_stopped()

	return out


func force_start_next_wave():
	if wave_is_in_progress():
		return

	_timer_between_waves.stop()
	_start_next_wave()


func _on_Wave_ended():
	var current_wave = get_current_wave()
	if current_wave.state == Wave.State.CLEARED:
		print_verbose("Wave [%s] is cleared." % current_wave)
		end_current_wave()
	else:
		push_error("Wave [%s] has ended but the state is invalid." % [current_wave])
	
